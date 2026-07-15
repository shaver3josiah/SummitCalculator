import AVFoundation
import os

/// Tiny self-contained synth that plays ONE short, soft, RISING major cue
/// (root → major third → perfect fifth, ~0.35s) for uplifting transitions
/// (modeswitch / success / startup). It rises by construction, so it can only
/// ever sound like a lift — never a downward "disappointment" — regardless of
/// what the bundled mp3s happen to sound like.
///
/// Coexists with SoundPlayer's shared AVAudioSession (.playback, .mixWithOthers):
/// it NEVER reconfigures or deactivates the session. It only touches
/// `SoundPlayer.shared` so that session's one-time (idempotent) setup has run
/// before the first cue — in case the cue is the very first audio of the launch
/// (the "startup" event). Everything else mirrors WhiteNoisePlayer's safe
/// pattern: own engine + player node, lazy attach, torn down when idle,
/// `[weak self]`, no retain cycle.
///
/// `SoundStore.enabled` is respected upstream: the only real-playback caller
/// (`SoundStore.play`) guards on `enabled` before routing here. Preview is
/// intentionally exempt (matches existing preview semantics).
final class CueSynth: @unchecked Sendable {
    static let shared = CueSynth()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let logger = Logger(subsystem: "com.shaver.summitcalculator", category: "CueSynth")

    private let sampleRate: Double = 44_100
    private var attached = false
    private var buffer: AVAudioPCMBuffer?
    private var generation = 0            // bumped each play; guards the idle teardown

    private init() {
        // Under memory pressure free the (tiny) buffer + render graph, but only
        // when idle — never interrupt a playing cue. (Fires on main.)
        MemoryPressure.onWarning { [weak self] in
            guard let self, !self.player.isPlaying else { return }
            self.teardown()
        }
    }

    /// Play the rising cue at `gain` (0...1, the node's output volume). Call on main.
    func playRise(gain: Float) {
        // Ensure the shared session is configured WITHOUT us reconfiguring it:
        // SoundPlayer owns the session; touching its singleton runs its one-time
        // setup if the cue is the first audio of the launch.
        _ = SoundPlayer.shared

        attachIfNeeded()
        guard attached, let buffer else { return }
        guard startEngine() else { return }

        generation &+= 1
        let epoch = generation
        player.volume = min(max(gain, 0), 1)
        player.stop()                              // restart cleanly if a cue is still ringing
        player.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
            // Completion fires on a render thread — hop to main, and only tear
            // down if no newer cue has started since (generation unchanged).
            DispatchQueue.main.async {
                guard let self, self.generation == epoch, !self.player.isPlaying else { return }
                self.teardown()
            }
        }
        player.play()
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
        buffer = makeRiseBuffer(format: format)
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

    /// Stop + release everything except the shared session. Idempotent — safe to
    /// call when already torn down. `playRise()` rebuilds it all via attachIfNeeded().
    private func teardown() {
        player.stop()
        engine.stop()
        if attached {
            engine.detach(player)
            attached = false
        }
        buffer = nil
    }

    // MARK: - Cue buffer

    /// Three ascending notes of a major triad (root, major third, perfect fifth),
    /// each a soft sine under a raised-cosine (Hann) envelope so there are no
    /// clicks (soft attack + soft release), staggered into a gentle ~0.35s rise.
    /// Overlaps are clamped so the peak stays well under 1.0.
    private func makeRiseBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let step = 0.09                        // seconds between note onsets
        let noteLen = 0.18                     // seconds each note rings
        let total = step * 2 + noteLen         // ~0.36s
        let midi: [Double] = [72, 76, 79]      // C5, E5, G5 — a rising major triad
        let amp: Float = 0.22                  // soft; overlaps clamped below

        let frames = AVAudioFrameCount(sampleRate * total)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        guard let channels = buffer.floatChannelData else { return nil }
        let channelCount = Int(format.channelCount)
        let noteFrames = Int(sampleRate * noteLen)
        let stepFrames = Int(sampleRate * step)

        for (i, m) in midi.enumerated() {
            let freq = 440.0 * pow(2.0, (m - 69.0) / 12.0)
            let startFrame = i * stepFrames
            for n in 0..<noteFrames {
                let idx = startFrame + n
                if idx >= Int(frames) { break }
                let t = Double(n) / sampleRate
                // Hann envelope 0→1→0 across the note: soft attack + release.
                let env = 0.5 - 0.5 * cos(2.0 * Double.pi * Double(n) / Double(noteFrames))
                let s = Float(sin(2.0 * Double.pi * freq * t) * env) * amp
                for ch in 0..<channelCount {
                    let mixed = channels[ch][idx] + s
                    channels[ch][idx] = max(-1, min(1, mixed))   // clamp overlaps
                }
            }
        }
        return buffer
    }
}
