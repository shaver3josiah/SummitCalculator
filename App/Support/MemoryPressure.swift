import UIKit

/// Tiny fan-out hub for `UIApplication.didReceiveMemoryWarningNotification`.
/// Subsystems register a purge block via `onWarning`; every block fires on the
/// main thread when the OS signals memory pressure.
///
/// Thread-safety: a small `NSLock` guards the handler array and the one-shot
/// install flag, so `onWarning` is safe to call from any thread (singleton
/// inits may run off-main). Handlers themselves always fire on `.main`.
///
/// Handlers capture their owning singleton (SoundPlayer.shared /
/// WhiteNoisePlayer.shared) — intentional, not a retain cycle to worry about:
/// those singletons live for the whole process, and the closures are retained
/// here for the process lifetime too (we never remove the observer).
enum MemoryPressure {
    private static let lock = NSLock()
    private static var handlers: [() -> Void] = []
    private static var installed = false

    /// Register `handler` to run on the next — and every subsequent — memory
    /// warning. The single NotificationCenter observer is installed lazily on
    /// the first registration and never removed.
    static func onWarning(_ handler: @escaping () -> Void) {
        lock.lock()
        handlers.append(handler)
        let needsInstall = !installed
        installed = true
        lock.unlock()

        guard needsInstall else { return }   // observer installs exactly once
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            lock.lock()
            let snapshot = handlers          // copy so handlers can run lock-free
            lock.unlock()
            snapshot.forEach { $0() }
        }
    }
}
