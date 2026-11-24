import SwiftUI

/// Ikon besar dengan halo putih berlapis (Figma: hero di layar 10, 11, dan 12).
struct HeroIcon: View {
    let systemImage: String
    var fill: Color = MColor.brand700

    var body: some View {
        ZStack {
            Circle()
                .fill(MColor.n0.opacity(0.45))
                .frame(width: 152, height: 152)
                .shadow(color: MColor.brand900.opacity(0.06), radius: 20, y: 8)
            Circle()
                .fill(MColor.n0.opacity(0.7))
                .frame(width: 112, height: 112)
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(MColor.n0)
                .frame(width: 76, height: 76)
                .background(fill, in: .circle)
        }
        .accessibilityHidden(true)
    }
}

/// Penanda halaman onboarding: capsule panjang untuk halaman aktif.
struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? MColor.brand700 : MColor.n200)
                    .frame(width: index == current ? 22 : 7, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Langkah \(current + 1) dari \(count)")
    }
}
