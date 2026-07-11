import SwiftUI

// Summit type roles per the Summit Design System: Bitter (slab) replaces
// Playfair Display, Archivo replaces Quicksand, Rye (carved woodtype) replaces
// Great Vibes. Families must match the ttf files fetched by scripts/fetch_fonts.sh.
enum SummitFontRole {
    static let bodyFamily = "Archivo"
    static let numberFamily = "Bitter"
    static let scriptFamily = "Rye"
}

func summitBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(SummitFontRole.bodyFamily, size: size).weight(weight)
}

func summitNumber(_ size: CGFloat, weight: Font.Weight = .medium, italic: Bool = false) -> Font {
    if italic {
        return .custom(SummitFontRole.numberFamily, size: size).italic().weight(weight)
    }
    return .custom(SummitFontRole.numberFamily, size: size).weight(weight)
}

func summitScript(_ size: CGFloat) -> Font {
    .custom(SummitFontRole.scriptFamily, size: size)
}
