import AVFoundation
import os

final class SoundPlayer: @unchecked Sendable {
    static let shared = SoundPlayer()

    // URLs are resolved + validated once at init (cheap — no decode); the actual
    // AVAudioPlayers are built on demand in play() and dropped on memory warning.
    // Both dicts are touched only from the sound-event path (SoundStore, main
    // thread), so no lock. ponytail: main-confined, add a lock only if a caller
    // ever plays off-main.
    private var urls: [String: URL] = [:]
    private var players: [String: AVAudioPlayer] = [:]
    private let soundNames = [
        "tap1", "tap2", "tap3", "tap4", "tap5",
        "operator", "equals", "clear", "error", "success",
        "modeswitch", "easteregg", "startup"
    ]
    private var sessionConfigured = false
    private let logger = Logger(subsystem: "com.shaver.summitcalculator", category: "SoundPlayer")

    private init() {
        configureSession()
        resolveURLs()
        // Purge decoded players under memory pressure; they rebuild on next play().
        MemoryPressure.onWarning { [weak self] in self?.players.removeAll() }
        // After a media-services daemon reset every cached AVAudioPlayer is dead
        // and the session config is gone: drop the players (they rebuild on next
        // play(), same as the memory-warning path) and reconfigure the session.
        // Singleton lives for the app's lifetime, so we never remove the observer.
        _ = NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.players.removeAll()
            self.sessionConfigured = false
            self.configureSession()
        }
    }

    private func configureSession() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            sessionConfigured = false
        }
    }

    /// Resolve + validate all 13 bundled mp3 URLs up front, so a missing asset is
    /// still caught at launch with the same log + DEBUG assert as before. We only
    /// stop short of decoding them — AVAudioPlayer creation moves to first play().
    private func resolveURLs() {
        var missing: [String] = []
        for name in soundNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
                missing.append(name)
                continue
            }
            urls[name] = url
        }
        if !missing.isEmpty {
            logger.error("Missing bundled sounds: \(missing.joined(separator: ", "), privacy: .public)")
            #if DEBUG
            assertionFailure("Missing bundled sounds: \(missing.joined(separator: ", "))")
            #endif
        }
    }

    /// Build-on-demand + cache. prepareToPlay() on a small keypad mp3 is ~a few
    /// ms; the keypad tap already tolerates that (the sound isn't in the touch's
    /// critical path), so first-tap decode is the accepted cost of not holding 13
    /// decoded players resident. After the first play of a given sound it stays
    /// warm for the session (until a memory warning drops it).
    private func player(for name: String) -> AVAudioPlayer? {
        if let player = players[name] { return player }
        guard let url = urls[name] else { return nil }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        players[name] = player
        return player
    }

    func play(_ name: String, gain: Float) {
        guard let player = player(for: name) else {
            logger.error("No sound available for: \(name, privacy: .public)")
            return
        }
        player.currentTime = 0
        player.volume = gain
        player.play()
    }
}
