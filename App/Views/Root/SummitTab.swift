import Foundation

enum SummitTab: String, CaseIterable, Identifiable {
    case calc
    case proj
    case lists
    case kitchen
    case tools
    case budget
    case music

    var id: String { rawValue }

    var label: String {
        switch self {
        case .calc: return "Calculator"
        case .proj: return "Projection"
        case .lists: return "Lists"
        case .kitchen: return "Kitchen"
        case .tools: return "Tools"
        case .budget: return "Monthly Budget"
        case .music: return "Music"
        }
    }

    var symbol: String {
        switch self {
        case .calc: return "plus.slash.minus"
        case .proj: return "chart.line.uptrend.xyaxis"
        case .lists: return "list.bullet"
        case .kitchen: return "fork.knife"
        case .tools: return "wrench.and.screwdriver"
        case .budget: return "wallet.pass"
        case .music: return "music.note"
        }
    }
}
