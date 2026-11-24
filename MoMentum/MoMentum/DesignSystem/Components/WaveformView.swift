import SwiftUI

/// Bar vertikal dari level audio 0...1 (Figma: Waveform di layar 01, 02, 03).
/// Bar sebelum `progress` tampil penuh, sisanya opasitas 40%.
struct WaveformView: View {
    let levels: [Double]
    var progress: Double = 1
    var color: Color = MColor.n400
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 4
    var minBarHeight: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            guard !levels.isEmpty else { return }
            let step = barWidth + spacing
            let totalWidth = CGFloat(levels.count) * step - spacing
            let playedCount = Int(Double(levels.count) * min(max(progress, 0), 1))
            var x = (size.width - totalWidth) / 2

            for (index, level) in levels.enumerated() {
                let height = max(minBarHeight, CGFloat(min(max(level, 0), 1)) * size.height)
                let rect = CGRect(x: x, y: (size.height - height) / 2, width: barWidth, height: height)
                let opacity = index < playedCount ? 1.0 : 0.4
                context.fill(
                    Path(roundedRect: rect, cornerRadius: barWidth / 2),
                    with: .color(color.opacity(opacity))
                )
                x += step
            }
        }
        .accessibilityHidden(true)
    }
}

extension WaveformView {
    /// Pola level tetap untuk waveform dekoratif (bukan dari mikrofon).
    static func decorativeLevels(count: Int, seed: Double = 0) -> [Double] {
        (0..<count).map { index in
            let x = Double(index) + seed
            let wave = abs(sin(x * 0.9)) * 0.55 + abs(sin(x * 2.3 + 1)) * 0.35
            return min(1, 0.2 + wave * 0.8)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        WaveformView(levels: WaveformView.decorativeLevels(count: 24))
            .frame(height: 72)
        WaveformView(levels: WaveformView.decorativeLevels(count: 40, seed: 3), progress: 0.5, color: .white)
            .frame(height: 100)
            .background(MColor.brand700)
    }
    .padding()
}
