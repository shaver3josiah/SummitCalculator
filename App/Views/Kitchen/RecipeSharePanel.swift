import SwiftUI
import SummitCore
import CoreImage
import CoreImage.CIFilterBuiltins

struct RecipeSharePanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var rawUrl = ""
    @State private var alias = ""
    @State private var qrImage: Image?
    @State private var qrEpoch = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Paste the recipe link", text: $rawUrl, prompt: Text("Paste the recipe link").foregroundStyle(theme.color("muted")))
                .font(summitBody(14))
                .foregroundStyle(theme.color("text"))
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))

            HStack {
                TextField("Name this QR (e.g. Blueberry_Muffins)", text: $alias, prompt: Text("Name this QR (e.g. Blueberry_Muffins)").foregroundStyle(theme.color("muted")))
                    .font(summitBody(13))
                    .foregroundStyle(theme.color("text"))
                Button("Make QR") {
                    generateQR()
                }
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))

            Text("A QR code works fully offline. Make one, then show it or save the image; scanning opens the recipe.")
                .font(summitBody(11))
                .foregroundStyle(theme.color("muted"))

            if let qrImage {
                VStack(spacing: 10) {
                    qrImage
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if theme.shimmerOn {
                                EncircleOutline(trigger: qrEpoch, cornerRadius: 12, lineWidth: 2.5)
                            }
                        }
                        .transition(theme.motionEnabled && !reduceMotion
                            ? .scale(scale: 0.92).combined(with: .opacity)
                            : .opacity)

                    ShareLink(
                        item: qrImage,
                        preview: SharePreview(alias.isEmpty ? "Recipe QR" : alias, image: qrImage)
                    )
                    .font(summitBody(13, weight: .medium))
                }
                .frame(maxWidth: .infinity)
            } else {
                mysteryPreview
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
    }

    /// A veiled stand-in where the QR will appear — a blurred not-quite-code
    /// so making one feels like unwrapping something.
    private var mysteryPreview: some View {
        VStack(spacing: 10) {
            ZStack {
                MysteryQRPattern()
                    .fill(theme.color("deep").opacity(0.35))
                    .background(theme.color("surfaceSoft"))
                    .blur(radius: 5)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(theme.color("flowerCenter"))
            }
            .frame(width: 200, height: 200)
            .overlay {
                if theme.shimmerOn {
                    EncircleOutline(trigger: 0, cornerRadius: 12, lineWidth: 2.5, settleOpacity: 0.3)
                }
            }

            Text("Your QR will appear here")
                .font(summitBody(12))
                .foregroundStyle(theme.color("muted"))
        }
        .frame(maxWidth: .infinity)
    }

    /// One shared CIContext for every QR render. A CIContext holds multi-MB
    /// GPU/colorspace state, so building one per tap churned that memory needlessly.
    private static let ciContext = CIContext(options: [.cacheIntermediates: false])

    private func generateQR() {
        let cleaned = RecipeParse.cleanUrl(rawUrl)
        guard !cleaned.isEmpty else { return }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(cleaned.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return }
        let scale = 200.0 / outputImage.extent.width
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = Self.ciContext.createCGImage(scaled, from: scaled.extent) else { return }
        withAnimation(theme.motionEnabled && !reduceMotion ? SummitMotion.glide : nil) {
            qrImage = Image(decorative: cgImage, scale: 1.0)
        }
        qrEpoch += 1
        theme.triggerCurtain()
    }
}

/// Deterministic scatter of squares that suggests a QR code without being one.
private struct MysteryQRPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var rng = SeededGenerator(seed: 4816)
        let grid = 12
        let cell = rect.width / CGFloat(grid)
        for row in 0..<grid {
            for col in 0..<grid where Bool.random(using: &rng) {
                path.addRect(CGRect(
                    x: rect.minX + CGFloat(col) * cell + cell * 0.12,
                    y: rect.minY + CGFloat(row) * cell + cell * 0.12,
                    width: cell * 0.76,
                    height: cell * 0.76
                ))
            }
        }
        return path
    }
}
