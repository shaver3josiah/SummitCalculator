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
    var digitChordHook: ((Int) -> Bool)?

    static let defaultMap: [String: String] = [
        "clear": "clear", "sign": "operator", "percent": "operator", "dot": "rotate", "equals": "equals",
        "op+": "operator", "op-": "operator", "op*": "operator", "op/": "operator",
        "d0": "rotate", "d1": "rotate", "d2": "rotate", "d3": "rotate", "d4": "rotate",
        "d5": "rotate", "d6": "rotate", "d7": "rotate", "d8": "rotate", "d9": "rotate",
        "modeswitch": "modeswitch", "success": "success", "error": "error",
        "easteregg": "easteregg", "startup": "startup", "memory": "tap3"
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
        if value == "rotate" {
            playTap()
            return
        }
        let gain = Self.gainTable[event] ?? Self.defaultGain
        SoundPlayer.shared.play(value, gain: gain)
    }

    private func playTap() {
        let name = Self.tapRotation[tapIndex % Self.tapRotation.count]
        tapIndex += 1
        SoundPlayer.shared.play(name, gain: Self.tapGain)
    }

    func preview(_ soundName: String) {
        if soundName == "rotate" {
            playTap()
        } else if soundName != "silent" {
            SoundPlayer.shared.play(soundName, gain: Self.defaultGain)
        }
    }

    func setEvent(_ event: String, to soundName: String) {
        eventMap[event] = soundName
    }

    func resetToDefaults() {
        eventMap = [:]
    }

    private func persistPrefs() {
        let prefs = SoundPrefs(enabled: enabled, hapticsEnabled: hapticsEnabled, eventMap: eventMap)
        JSONStore.shared.set(.soundmap, prefs)
    }
}

private struct SoundPrefs: Codable {
    var enabled: Bool
    var hapticsEnabled: Bool
    var eventMap: [String: String]
}
