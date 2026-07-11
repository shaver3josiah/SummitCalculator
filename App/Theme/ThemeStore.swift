import SwiftUI
import SummitCore

@Observable
final class ThemeStore {
    var spec: ThemeSpec
    var presetNames: [String] = ["lake", "pine", "cedar", "granite", "river"]
    var radius: CGFloat = 16
    var showTabLabels: Bool = true {
        didSet { JSONStore.shared.set(.tabLabels, showTabLabels) }
    }
    // Calc display-card left column visibility (both default on). Same persistence
    // shape as showTabLabels — a plain Bool file, loaded in init, saved on didSet.
    var showCalcLog: Bool = true {
        didSet { JSONStore.shared.set(.calcLog, showCalcLog) }
    }
    var showChordWheel: Bool = true {
        didSet { JSONStore.shared.set(.chordWheel, showChordWheel) }
    }

    // Motion preferences + first-visit tracking. Kept here because ThemeStore is
    // already injected into every view that needs to gate an animation.
    var motionEnabled: Bool = true { didSet { persistMotion() } }
    var leavesEnabled: Bool = true { didSet { persistMotion() } }
    var shimmerEnabled: Bool = true { didSet { persistMotion() } }
    private var seenTabs: Set<String> = []
    var curtainEpoch: Int = 0   // transient; bumped to fire the leaf curtain

    /// Effective gates — a sub-effect is on only when the master switch is too.
    var leavesOn: Bool { motionEnabled && leavesEnabled }
    var shimmerOn: Bool { motionEnabled && shimmerEnabled }

    /// True the first time (ever) a tab is opened; marks it seen and persists.
    func firstVisit(_ tabRaw: String) -> Bool {
        guard !seenTabs.contains(tabRaw) else { return false }
        seenTabs.insert(tabRaw)
        persistMotion()
        return true
    }

    /// Fire the top-down leaf curtain (no-op when leaves are disabled).
    func triggerCurtain() {
        guard leavesOn else { return }
        curtainEpoch += 1
    }

    private var customTokens: [String: String]

    init() {
        let savedPresetName = JSONStore.shared.get(.theme, as: String.self) ?? "lake"
        let savedCustom = JSONStore.shared.get(.custom, as: [String: String].self)
        let tokens = savedCustom ?? ThemeStore.presetTokens(for: "lake")
        customTokens = tokens

        let initialSpec: ThemeSpec
        if savedPresetName == "custom" {
            initialSpec = ThemeSpec(name: "custom", tokens: tokens)
        } else {
            initialSpec = ThemeSpec(name: savedPresetName, tokens: ThemeStore.presetTokens(for: savedPresetName))
        }
        spec = initialSpec
        radius = ThemeStore.parseRadius(initialSpec.tokens["radius"])
        showTabLabels = JSONStore.shared.get(.tabLabels, as: Bool.self) ?? true
        showCalcLog = JSONStore.shared.get(.calcLog, as: Bool.self) ?? true
        showChordWheel = JSONStore.shared.get(.chordWheel, as: Bool.self) ?? true

        let motion = JSONStore.shared.get(.motion, as: MotionPrefs.self)
        seenTabs = Set(motion?.seenTabs ?? [])   // before the prefs — their didSet persists seenTabs
        motionEnabled = motion?.motion ?? true
        leavesEnabled = motion?.leaves ?? true
        shimmerEnabled = motion?.shimmer ?? true
    }

    private func persistMotion() {
        JSONStore.shared.set(.motion, MotionPrefs(
            motion: motionEnabled, leaves: leavesEnabled,
            shimmer: shimmerEnabled, seenTabs: Array(seenTabs)
        ))
    }

    func color(_ token: String) -> Color {
        guard let hex = spec.tokens[token] else { return .clear }
        return Color(hex: hex) ?? .clear
    }

    func setPreset(_ name: String) {
        if name == "custom" {
            spec = ThemeSpec(name: "custom", tokens: customTokens)
        } else {
            spec = ThemeSpec(name: name, tokens: ThemeStore.presetTokens(for: name))
        }
        radius = ThemeStore.parseRadius(spec.tokens["radius"])
        JSONStore.shared.set(.theme, spec.name)
    }

    func setCustomToken(_ token: String, hex: String) {
        customTokens[token] = hex
        JSONStore.shared.set(.custom, customTokens)
        if spec.name == "custom" {
            spec = ThemeSpec(name: "custom", tokens: customTokens)
        }
    }

    static let editableTokenOrder: [String] = [
        "bg", "surface", "surfaceSoft", "surface2", "primary", "primaryStrong",
        "deep", "text", "muted", "line", "flowerCenter", "good"
    ]

    static func editableTokenLabel(_ token: String) -> String {
        switch token {
        case "bg": return "Page background"
        case "surface": return "Card surface"
        case "surfaceSoft": return "Keys & panels"
        case "surface2": return "Accent panels"
        case "primary": return "Ridge accent"
        case "primaryStrong": return "Strong accent"
        case "deep": return "Headlines"
        case "text": return "Main text"
        case "muted": return "Soft text"
        case "line": return "Borders"
        case "flowerCenter": return "Summit peak"
        case "good": return "Growth color"
        default: return token
        }
    }

    private static func parseRadius(_ raw: String?) -> CGFloat {
        guard let raw, let value = Double(raw) else { return 16 }
        return CGFloat(value)
    }

    // Summit palette: five dark rustic presets ported from the Summit Design System
    // (Summit/extracted/tokens/colors.css). All dark; "deep" is the light headline
    // color on dark surfaces, "flowerCenter" is the amber peak accent (legacy key).
    private static func presetTokens(for name: String) -> [String: String] {
        let base: [String: String] = [
            "shadow": "rgba(0,0,0,.45)",
            "ripple": "rgba(255,255,255,.18)",
            "sh1": "0 1px 2px rgba(0,0,0,.35),0 1px 1px rgba(0,0,0,.25)",
            "radius": "16",
            "good": "#5FBF84",
            "flowerCenter": "#D9A441"
        ]
        switch name {
        case "pine":
            return base.merging([
                "bg": "#161A14",
                "surface": "#232920",
                "surfaceSoft": "#2C3427",
                "surface2": "#272E22",
                "primary": "#7FA985",
                "primaryStrong": "#5E8C61",
                "deep": "#CFE3CC",
                "text": "#E8EAE0",
                "muted": "#9AA692",
                "line": "#3A4233"
            ]) { _, new in new }
        case "cedar":
            return base.merging([
                "bg": "#1C1610",
                "surface": "#2A211A",
                "surfaceSoft": "#362A1F",
                "surface2": "#302519",
                "primary": "#C58757",
                "primaryStrong": "#A9683F",
                "deep": "#E7C9A9",
                "text": "#EFE6DA",
                "muted": "#A8988A",
                "line": "#453729",
                "shadow": "rgba(0,0,0,.5)"
            ]) { _, new in new }
        case "granite":
            return base.merging([
                "bg": "#14181B",
                "surface": "#21282D",
                "surfaceSoft": "#2B343B",
                "surface2": "#262E34",
                "primary": "#8AA5B5",
                "primaryStrong": "#5B7482",
                "deep": "#C9D9E2",
                "text": "#E4EAEE",
                "muted": "#93A1AB",
                "line": "#37424A",
                "shadow": "rgba(0,0,0,.5)"
            ]) { _, new in new }
        case "river":
            return base.merging([
                "bg": "#101917",
                "surface": "#1D2926",
                "surfaceSoft": "#26352F",
                "surface2": "#223029",
                "primary": "#6FBCAC",
                "primaryStrong": "#3E8E7E",
                "deep": "#BFE2D8",
                "text": "#E1EEEA",
                "muted": "#8FA69E",
                "line": "#32443E",
                "flowerCenter": "#E0B04F",
                "shadow": "rgba(0,0,0,.5)"
            ]) { _, new in new }
        default: // lake — steel-blue night-lake default
            return base.merging([
                "bg": "#12181D",
                "surface": "#1E262D",
                "surfaceSoft": "#28333C",
                "surface2": "#232D35",
                "primary": "#6FA3C7",
                "primaryStrong": "#4A7FA5",
                "deep": "#C8DEEF",
                "text": "#E4EAEF",
                "muted": "#8FA0AD",
                "line": "#35424C"
            ]) { _, new in new }
        }
    }
}

private struct MotionPrefs: Codable {
    var motion: Bool
    var leaves: Bool
    var shimmer: Bool
    var seenTabs: [String]
}

extension Color {
    init?(hex: String) {
        var normalized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasPrefix("#") {
            normalized.removeFirst()
        }
        guard normalized.count == 6, let value = UInt64(normalized, radix: 16) else {
            return nil
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
