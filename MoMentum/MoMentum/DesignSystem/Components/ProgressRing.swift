import SwiftUI

/// Cincin progres (Figma: Progress Ring di layar 05). Stroke 10 pt, `brand700` di atas `brand100`.
/// `progress == nil` berarti progres belum diketahui: busur pendek berputar.
struct ProgressRing: View {
    let progress: Double?
    var lineWidth: CGFloat = 10

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(MColor.brand100, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress.map { min(max($0, 0), 1) } ?? 0.25)
                .stroke(MColor.brand700, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90 + (progress == nil && isSpinning ? 360 : 0)))
                .animation(
                    progress == nil && !reduceMotion ? .linear(duration: 1.2).repeatForever(autoreverses: false) : .default,
                    value: isSpinning
                )
        }
        .onAppear { isSpinning = true }
        .accessibilityElement()
        .accessibilityLabel("Progres")
        .accessibilityValue(progress.map { "\(Int(($0 * 100).rounded())) persen" } ?? "Sedang diproses")
    }
}

#Preview {
    HStack(spacing: 32) {
        ProgressRing(progress: 0.62).frame(width: 120, height: 120)
        ProgressRing(progress: nil).frame(width: 120, height: 120)
    }
    .padding()
}
