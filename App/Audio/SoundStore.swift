import SwiftUI
import SummitCore

@Observable
final class SoundStore {
    var enabled: Bool {
        didSet { persistPrefs() }
    }
    var hapticsEnabled: Bool {
        didSet { persistPrefs() }
    }
    var isStudioPresented: Bool = false
    var eventMap: [String: String] {
        didSet { persistPrefs() }
    }
    /// Per-event volume multiplier (0.0…1.5, default 1.0). A missing entry falls
    /// back to `defaultVolumes` (0.6 for clear/dot) then 1.0 — see volumeMultiplier.
    var eventVolumes: [String: Float] {
        didSet { persistPrefs() }
    }
    var digitChordHook: ((Int) -> Bool)?

    // "cue" routes to CueSynth's uplifting rising cue instead of an mp3, so
    // transition events feel like a lift by construction. Users can override any
    // of these to an mp3 via eventMap and that explicit choice is honored.
    // Digits and dot default to the soft "thud" block knock; clear (AC and ⌫)
    // defaults to the lighter "thok" wood knock.
    static let defaultMap: [String: String] = [
        "clear": "thok", "sign": "operator", "percent": "operator", "dot": "thud", "equals": "equals",
        "op+": "operator", "op-": "operator", "op*": "operator", "op/": "operator",
        "d0": "thud", "d1": "thud", "d2": "thud", "d3": "thud", "d4": "thud",
        "d5": "thud", "d6": "thud", "d7": "thud", "d8": "thud", "d9": "thud",
        "modeswitch": "cue", "success": "cue", "error": "error",
        "easteregg": "easteregg", "startup": "cue", "memory": "tap3"
    ]

    /// Effective default volume when `eventVolumes` has no entry for an event.
    /// clear (⌫ delete AND AC) and dot (period) are quieter by default; the user
    /// can still override to anything by writing an explicit eventVolumes entry.
    static let defaultVolumes: [String: Float] = ["clear": 0.6, "dot": 0.6]

    /// Chunky + tactile: block thuds on every digit, wood knocks on operators,
    /// a cheerful two-note bell ding on the result.
    static let blockyMap: [String: String] = [
        "d0": "thud", "d1": "thud", "d2": "thud", "d3": "thud", "d4": "thud",
        "d5": "thud", "d6": "thud", "d7": "thud", "d8": "thud", "d9": "thud",
        "dot": "thud", "sign": "thok", "percent": "thok",
        "op+": "thok", "op-": "thok", "op*": "thok", "op/": "thok",
        "equals": "ding", "clear": "thud",
        "modeswitch": "thok", "success": "ding", "startup": "ding",
        "error": "error", "easteregg": "easteregg", "memory": "thok"
    ]

    /// Sci-fi console: laser zaps on digits, pews on operators, a warp rise
    /// for the result and every transition.
    static let galaxyMap: [String: String] = [
        "d0": "zap", "d1": "zap", "d2": "zap", "d3": "zap", "d4": "zap",
        "d5": "zap", "d6": "zap", "d7": "zap", "d8": "zap", "d9": "zap",
        "dot": "zap", "sign": "pew", "percent": "pew",
        "op+": "pew", "op-": "pew", "op*": "pew", "op/": "pew",
        "equals": "warp", "clear": "zap",
        "modeswitch": "warp", "success": "warp", "startup": "warp",
        "error": "error", "easteregg": "easteregg", "memory": "zap"
    ]

    /// Heroic fantasy: harp plucks on digits, deep drums on operators, a noble
    /// horn swell for the result and every transition.
    static let questMap: [String: String] = [
        "d0": "harp", "d1": "harp", "d2": "harp", "d3": "harp", "d4": "harp",
        "d5": "harp", "d6": "harp", "d7": "harp", "d8": "harp", "d9": "harp",
        "dot": "harp", "sign": "drum", "percent": "drum",
        "op+": "drum", "op-": "drum", "op*": "drum", "op/": "drum",
        "equals": "horn", "clear": "harp",
        "modeswitch": "horn", "success": "horn", "startup": "horn",
        "error": "error", "easteregg": "easteregg", "memory": "harp"
    ]

    /// A playful mapping composed entirely from the EXISTING sound palette
    /// (optionChoices) — no new mp3s. Music-box "rotate" on all digits + dot,
    /// springy "easteregg" on equals, playful taps on operators, and the
    /// uplifting "cue" kept on the transition events so they stay uplifting.
    static let funMap: [String: String] = [
        "d0": "rotate", "d1": "rotate", "d2": "rotate", "d3": "rotate", "d4": "rotate",
        "d5": "rotate", "d6": "rotate", "d7": "rotate", "d8": "rotate", "d9": "rotate",
        "dot": "rotate",
        "sign": "tap5", "percent": "tap2",
        "op+": "tap1", "op-": "tap2", "op*": "tap3", "op/": "tap4",
        "equals": "easteregg", "clear": "tap5",
        "modeswitch": "cue", "success": "cue", "startup": "cue",
        "error": "error", "easteregg": "easteregg", "memory": "rotate"
    ]

    /// Dreamy + lush: music box on every key, an uplifting rise to finish.
    static let alpineMap: [String: String] = [
        "d0": "rotate", "d1": "rotate", "d2": "rotate", "d3": "rotate", "d4": "rotate",
        "d5": "rotate", "d6": "rotate", "d7": "rotate", "d8": "rotate", "d9": "rotate",
        "dot": "rotate", "sign": "rotate", "percent": "rotate",
        "op+": "rotate", "op-": "rotate", "op*": "rotate", "op/": "rotate",
        "equals": "cue", "clear": "tap3",
        "modeswitch": "cue", "success": "cue", "startup": "cue",
        "error": "error", "easteregg": "easteregg", "memory": "rotate"
    ]

    /// Restrained + refined: one quiet tap per key, a clean chime on the result.
    static let timberMap: [String: String] = [
        "d0": "tap4", "d1": "tap4", "d2": "tap4", "d3": "tap4", "d4": "tap4",
        "d5": "tap4", "d6": "tap4", "d7": "tap4", "d8": "tap4", "d9": "tap4",
        "dot": "tap1", "sign": "tap2", "percent": "tap2",
        "op+": "tap2", "op-": "tap2", "op*": "tap2", "op/": "tap2",
        "equals": "success", "clear": "tap5",
        "modeswitch": "cue", "success": "success", "startup": "cue",
        "error": "error", "easteregg": "easteregg", "memory": "tap3"
    ]

    /// Named sound presets shown in the Sound Studio (freely switchable). A nil map
    /// means "back to the built-in defaults" (the Classic set).
    struct Preset: Identifiable {
        let id: String
        let systemImage: String
        let map: [String: String]?
        var name: String { id }
    }
    static let presets: [Preset] = [
        Preset(id: "Classic", systemImage: "music.note", map: nil),
        Preset(id: "Blocky", systemImage: "cube.fill", map: blockyMap),
        Preset(id: "Galaxy", systemImage: "moon.stars.fill", map: galaxyMap),
        Preset(id: "Quest", systemImage: "shield.fill", map: questMap),
        Preset(id: "Fun", systemImage: "sparkles", map: funMap),
        Preset(id: "Alpine", systemImage: "mountain.2.fill", map: alpineMap),
        Preset(id: "Timber", systemImage: "tree.fill", map: timberMap)
    ]

    static let eventOrder: [String] = [
        "d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9",
        "dot", "sign", "percent", "op+", "op-", "op*", "op/", "equals", "clear",
        "modeswitch", "success", "error", "easteregg", "startup", "memory"
    ]

    static let keypadEvents: [(String, String)] = [
        ("clear", "AC"), ("sign", "+/-"), ("percent", "%"), ("op/", "÷"),
        ("d7", "7"), ("d8", "8"), ("d9", "9"), ("op*", "×"),
        ("d4", "4"), ("d5", "5"), ("d6", "6"), ("op-", "-"),
        ("d1", "1"), ("d2", "2"), ("d3", "3"), ("op+", "+"),
        ("d0", "0"), ("dot", "."), ("equals", "=")
    ]

    static let namedEvents: [(String, String)] = [
        ("modeswitch", "Mode switch"), ("success", "Calc success"), ("error", "Error"),
        ("easteregg", "Easter egg"), ("startup", "Startup"), ("memory", "Memory keys")
    ]

    static let optionChoices: [(String, String)] = [
        ("rotate", "Music box (rotating)"),
        ("cue", "Uplifting rise"),
        ("thud", "Block thud"), ("thok", "Wood knock"), ("ding", "Bell ding"),
        ("zap", "Laser zap"), ("pew", "Laser pew"), ("warp", "Warp rise"),
        ("harp", "Harp pluck"), ("drum", "Deep drum"), ("horn", "Epic horn"),
        ("tap1", "Tap 1"), ("tap2", "Tap 2"), ("tap3", "Tap 3"), ("tap4", "Tap 4"), ("tap5", "Tap 5"),
        ("operator", "Operator"), ("equals", "Equals"), ("clear", "Clear"), ("error", "Error"),
        ("success", "Success"), ("modeswitch", "Mode switch"), ("easteregg", "Easter egg"),
        ("startup", "Startup"), ("silent", "Silent")
    ]

    private static let gainTable: [String: Float] = [
        "equals": 0.5, "success": 0.55, "easteregg": 0.6,
        "startup": 0.5, "modeswitch": 0.5, "error": 0.4, "memory": 0.4
    ]
    private static let defaultGain: Float = 0.45
    private static let tapRotation = ["tap1", "tap2", "tap3", "tap4", "tap5"]
    private static let tapGain: Float = 0.45
    private static let digitEvents: Set<String> = [
        "d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9"
    ]
    private static let operatorChordIndices: [String: Int] = [
        "op+": 10, "op-": 11, "op*": 12, "op/": 13
    ]

    private var tapIndex = 0

    init() {
        let prefs = JSONStore.shared.get(.soundmap, as: SoundPrefs.self)
        enabled = prefs?.enabled ?? true
        hapticsEnabled = prefs?.hapticsEnabled ?? true
        eventMap = prefs?.eventMap ?? [:]
        eventVolumes = prefs?.eventVolumes ?? [:]   // old blobs (no field) → empty; defaults apply on lookup
    }

    func play(_ event: String) {
        guard enabled else { return }
        if let chordIndex = digitFromKeyEvent(event) ?? Self.operatorChordIndices[event],
           digitChordHook?(chordIndex) == true {
            return
        }
        let value = eventMap[event] ?? Self.defaultMap[event] ?? "silent"
        resolve(value, event: event)
    }

    private func digitFromKeyEvent(_ event: String) -> Int? {
        guard Self.digitEvents.contains(event) else { return nil }
        return Int(event.dropFirst())
    }

    private func resolve(_ value: String, event: String) {
        guard value != "silent" else { return }
        // Base gain, then per-event volume multiplier, clamped ≤ 1.0 to avoid clipping.
        let base: Float = (value == "rotate") ? Self.tapGain : (Self.gainTable[event] ?? Self.defaultGain)
        let gain = min(1.0, base * volumeMultiplier(event))
        switch value {
        case "rotate": playTap(gain: gain)
        case "cue":    CueSynth.shared.playRise(gain: gain)   // uplifting rising cue, no mp3
        default:       SoundPlayer.shared.play(value, gain: gain)
        }
    }

    /// Effective volume multiplier for an event: explicit user value if set,
    /// else the per-event default (0.6 for clear/dot), else 1.0.
    private func volumeMultiplier(_ event: String) -> Float {
        eventVolumes[event] ?? Self.defaultVolumes[event] ?? 1.0
    }

    private func playTap(gain: Float) {
        let name = Self.tapRotation[tapIndex % Self.tapRotation.count]
        tapIndex += 1
        SoundPlayer.shared.play(name, gain: gain)
    }

    /// Preview the event's CURRENT mapping at the row's current volume — routes
    /// through the same `resolve` path as `play`, so cue/rotate/mp3 and the
    /// volume multiplier all match what actually plays. (Not gated on `enabled`,
    /// matching the previous preview semantics.)
    func preview(event eventId: String) {
        let value = eventMap[eventId] ?? Self.defaultMap[eventId] ?? "silent"
        resolve(value, event: eventId)
    }

    func setEvent(_ event: String, to soundName: String) {
        eventMap[event] = soundName
    }

    /// Current volume multiplier for an event (for the Sound Studio slider).
    func volume(for event: String) -> Float {
        volumeMultiplier(event)
    }

    /// Set an explicit per-event volume multiplier (clamped to 0.0…1.5).
    func setVolume(_ event: String, to value: Float) {
        eventVolumes[event] = min(max(value, 0), 1.5)
    }

    /// Apply a named preset. `nil` map resets to the built-in defaults (Classic).
    func applyPreset(_ preset: Preset) {
        eventMap = preset.map ?? [:]
    }

    func resetToDefaults() {
        eventMap = [:]
    }

    private func persistPrefs() {
        let prefs = SoundPrefs(
            enabled: enabled,
            hapticsEnabled: hapticsEnabled,
            eventMap: eventMap,
            eventVolumes: eventVolumes
        )
        JSONStore.shared.set(.soundmap, prefs)
    }
}

private struct SoundPrefs: Codable {
    var enabled: Bool
    var hapticsEnabled: Bool
    var eventMap: [String: String]
    // Optional so old saved blobs (which lack this field) decode to nil via the
    // synthesized decodeIfPresent — backward-compatible, never crashes.
    var eventVolumes: [String: Float]?
}
