import AVFoundation
import Observation
import os

/// Gentle looping white-noise player for the mark's hidden "calm" hold gesture.
/// It caps itself at 3 minutes (a foreground sleep-timer, since we hold no
/// background-audio entitlement) with a soft fade-out. The loop is click-free
/// because white noise has no periodicity and the buffer is filled to its full
/// capacity (`frameLength == frameCapacity`, no silent tail) before scheduling
/// with `.loops`, so the wrap-around is just more noise.
@Observable
final class WhiteNoisePlayer: @unchecked Sendable {
    static let shared = WhiteNoisePlayer()

    /// Drives the mark's subtle "active" cue. Observed by SwiftUI; mutate on main.
    private(set) var isPlaying = false

    // Own engine + player node. This coexists with SoundPlayer's AVAudioSession
    // (.playback, .mixWithOthers) — we never reconfigure or deactivate that session.
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let logger = Logger(subsystem: "com.shaver.summitcalculator", category: "WhiteNoisePlayer")

    private let sampleRate: Double = 44_100
    private let targetVolume: Float = 0.18

    private var attached = false
    private var buffer: AVAudioPCMBuffer?

    // Single-slot main-queue timers: one for the current volume ramp, one for the cap.
    private var rampTimer: DispatchSourceTimer?
    private var autoStopTimer: DispatchSourceTimer?

    private static let autoStopAfter: TimeInterval = 180   // 3 minutes
    private static let fadeIn: TimeInterval = 1.5
    private static let fadeOut: TimeInterval = 2.0

    private var interruptionObserver: NSObjectProtocol?

    private init() {
        // Block-based observer (this is a plain Swift class, so no @objc/#selector).
        // Singleton lives for the app's lifetime, so we never need to remove it.
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let self,
                  let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
            // Phone call etc. — stop cleanly (already on main). No auto-resume: minimal.
            self.stop()
        }

        // Under memory pressure, free the ~700KB buffer + render graph — but only
        // when idle. NEVER interrupt active playback for a warning. (Fires on main.)
        MemoryPressure.onWarning { [weak self] in
            guard let self, !self.isPlaying else { return }
            self.teardown()
        }
    }

    // MARK: - Public API

    func start() {
        cancelTimers()
        attachIfNeeded()
        guard attached, let buffer else { return }
        guard startEngine() else { return }

        // If we're restarting mid-fade-out the node is still looping — just ramp
        // back up. Otherwise (re)schedule the loop from silence.
        if !player.isPlaying {
            player.volume = 0
            player.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
            player.play()
        }
        setPlaying(true)
        rampVolume(to: targetVolume, over: Self.fadeIn)
        scheduleAutoStop()
    }

    func stop() {
        cancelTimers()
        setPlaying(false)               // cue clears immediately (incl. the 3-min cap)
        guard player.isPlaying else { return }
        rampVolume(to: 0, over: Self.fadeOut) { [weak self] in
            self?.teardown()            // full teardown so the buffer + graph free
        }
    }

    /// Stop and release everything except the session: stops the node + engine,
    /// detaches the node, and drops the ~700KB noise buffer. Idempotent — safe to
    /// call when already torn down. start() rebuilds it all via attachIfNeeded().
    /// A restart mid-fade-out never reaches here: start()'s cancelTimers() kills
    /// the fade-out ramp before its completion (this) can run.
    private func teardown() {
        player.stop()                   // releases the scheduled buffer ref first
        engine.stop()
        if attached {
            engine.detach(player)       // symmetric with attachIfNeeded's attach
            attached = false
        }
        buffer = nil                    // last strong ref → ~700KB freed
    }

    // MARK: - Engine graph

    private func attachIfNeeded() {
        guard !attached else { return }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            logger.error("could not create audio format")
            return
        }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        buffer = makeNoiseBuffer(format: format)
        attached = true
    }

    @discardableResult
    private func startEngine() -> Bool {
        guard !engine.isRunning else { return true }
        engine.prepare()
        do {
            try engine.start()
            return true
        } catch {
            logger.error("engine start failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// ~4s of gaussian-ish white noise, peak ~0.5. `frameLength` is set to the full
    /// `frameCapacity` so the looped buffer has no silent tail — the seamless-loop guarantee.
    private func makeNoiseBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(sampleRate * 4)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames                    // == frameCapacity → fully filled below
        guard let channels = buffer.floatChannelData else { return nil }
        let channelCount = Int(format.channelCount)
        var rng = SystemRandomNumberGenerator()
        for frame in 0..<Int(frames) {
            // Central-limit: averaging 3 uniforms gives a gaussian-ish bell in [-1, 1].
            let n = (Float.random(in: -1...1, using: &rng)
                   + Float.random(in: -1...1, using: &rng)
                   + Float.random(in: -1...1, using: &rng)) / 3
            let sample = n * 0.5                        // gentle peak ~0.5
            for ch in 0..<channelCount {
                channels[ch][frame] = sample
            }
        }
        return buffer
    }

    // MARK: - Volume ramp (AVAudioPlayerNode has no built-in ramp)

    private func rampVolume(to target: Float, over duration: TimeInterval, completion: (() -> Void)? = nil) {
        rampTimer?.cancel()
        let tick = 0.05
        let steps = max(1, Int(duration / tick))
        let start = player.volume
        let delta = target - start
        var step = 0
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + tick, repeating: tick)
        timer.setEventHandler { [weak self] in       // weak: don't let the timer pin state
            guard let self else { return }
            step += 1
            let progress = Float(min(step, steps)) / Float(steps)
            self.player.volume = start + delta * progress
            if step >= steps {
                self.rampTimer?.cancel()
                self.rampTimer = nil
                completion?()
            }
        }
        rampTimer = timer
        timer.resume()
    }

    // MARK: - 3-minute cap

    private func scheduleAutoStop() {
        autoStopTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + Self.autoStopAfter)   // one-shot
        timer.setEventHandler { [weak self] in
            self?.stop()
        }
        autoStopTimer = timer
        timer.resume()
    }

    private func cancelTimers() {
        rampTimer?.cancel(); rampTimer = nil
        autoStopTimer?.cancel(); autoStopTimer = nil
    }

    // MARK: - State + interruptions

    private func setPlaying(_ value: Bool) {
        if Thread.isMainThread {
            isPlaying = value
        } else {
            DispatchQueue.main.async { [weak self] in self?.isPlaying = value }
        }
    }
}
