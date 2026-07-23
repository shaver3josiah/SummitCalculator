import SwiftUI

/// The Base Camp Sessions tour: a friendly step-by-step demo of the whole tab.
/// MusicView owns the state machine (typewriter, auto-advance on load, etc.);
/// this file holds the step definitions, the bottom card, and the spotlight.
enum MusicTourStep: Int, CaseIterable {
    case welcome, library, write, slide, pads, controls, piano, done

    var title: String {
        switch self {
        case .welcome: return "Welcome to Base Camp Sessions 🏔️"
        case .library: return "A whole songbook"
        case .write: return "Or write your own"
        case .slide: return "Now the fun part"
        case .pads: return "Tap to play"
        case .controls: return "Make it yours"
        case .piano: return "One note at a time"
        case .done: return "You're ready! ⛰️"
        }
    }

    /// Kept short on purpose: these ride a slim one-line bar, not a panel.
    var message: String {
        switch self {
        case .welcome: return "Chords become soft piano. Want the quick tour?"
        case .library: return "Tap a card to browse — tap a song and it loads."
        case .write: return "Chords live in this box — watch me write some!"
        case .slide: return "Slide the thumb right to load your chords."
        case .pads: return "Every pad is a chord. Tap them in any order."
        case .controls: return "Tempo, strum, transpose — until it sounds like you."
        case .piano: return "This piano sprinkles single notes in. Try a twinkle."
        case .done: return "It all plays offline. Go make something beautiful."
        }
    }

    var primaryLabel: String? {
        switch self {
        case .welcome: return "Show me!"
        case .slide: return nil   // advances itself when she loads the chords
        case .done: return "Let's play"
        default: return "Next"
        }
    }
}

/// Bottom-docked tour bar. Deliberately SLIM — the tour is a guest on her
/// screen, never the host: one line of guidance, one small action, an X to end
/// it. It only ever appears because she tapped the tour button.
struct MusicTourCard: View {
    @Environment(ThemeStore.self) private var theme

    let step: MusicTourStep
    var onNext: () -> Void
    var onSkip: () -> Void
    var onAssist: (() -> Void)? = nil   // "Do it for me" on the slide step

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                // The step dots used to sit inline here and ate ~59pt of the
                // title's line box, truncating it on small phones. The count
                // now rides the title's accessibility label instead.
                Text(step.title)
                    .font(summitBody(13, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .accessibilityLabel("\(step.title). Step \(step.rawValue + 1) of \(MusicTourStep.allCases.count)")
                Text(step.message)
                    .font(summitBody(12))
                    .foregroundStyle(theme.color("muted"))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)

            if let label = step.primaryLabel {
                Button(action: onNext) {
                    Text(label)
                        .font(summitBody(13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(Capsule().fill(theme.color("primaryStrong")))
                }
                .buttonStyle(.plain)
            } else if let onAssist {
                Button(action: onAssist) {
                    Text("Do it for me")
                        .font(summitBody(13, weight: .semibold))
                        .foregroundStyle(theme.color("primaryStrong"))
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(Capsule().fill(theme.color("surfaceSoft")))
                }
                .buttonStyle(.plain)
            }

            Button(action: onSkip) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.color("muted"))
                    .frame(width: 30, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("End the tour")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.color("surface"))
                .shadow(color: theme.color("shadow"), radius: 14, y: 6)
        )
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(theme.color("line"), lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

/// Glow ring + gentle lift on the section the current tour step points at.
private struct TourSpotlightModifier: ViewModifier {
    @Environment(ThemeStore.self) private var theme
    let active: Bool
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [theme.color("primary"), theme.color("flowerCenter")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .shadow(color: theme.color("primary").opacity(0.45), radius: 10)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .scaleEffect(active ? 1.015 : 1)
            .animation(SummitMotion.springSoft, value: active)
    }
}

extension View {
    func tourSpotlight(_ active: Bool, cornerRadius: CGFloat = 22) -> some View {
        modifier(TourSpotlightModifier(active: active, cornerRadius: cornerRadius))
    }
}
