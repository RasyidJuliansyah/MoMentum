import SwiftUI

/// Tombol capsule setinggi ±52 pt.
/// - primary: hitam `n900`, teks putih
/// - secondary: abu `n100`, teks `n900`
/// - light: putih, teks `n900` (tombol Stop di atas latar gelap)
/// - glass: Liquid Glass, teks putih (tombol Tandai/Jeda di atas latar gelap)
struct CapsuleButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case light
        case glass
    }

    let kind: Kind
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, MSpace.md)
            .background {
                switch kind {
                case .primary: Capsule().fill(MColor.n900)
                case .secondary: Capsule().fill(MColor.n100)
                case .light: Capsule().fill(MColor.n0)
                case .glass: Color.clear
                }
            }
            .modifier(GlassIfNeeded(isGlass: kind == .glass))
            .contentShape(.capsule)
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.45)
    }

    private var foreground: Color {
        switch kind {
        case .primary, .glass: MColor.n0
        case .secondary, .light: MColor.n900
        }
    }
}

private struct GlassIfNeeded: ViewModifier {
    let isGlass: Bool

    func body(content: Content) -> some View {
        if isGlass {
            content.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            content
        }
    }
}

extension ButtonStyle where Self == CapsuleButtonStyle {
    static var primaryCapsule: CapsuleButtonStyle { CapsuleButtonStyle(kind: .primary) }
    static var secondaryCapsule: CapsuleButtonStyle { CapsuleButtonStyle(kind: .secondary) }
    static var lightCapsule: CapsuleButtonStyle { CapsuleButtonStyle(kind: .light) }
    static var glassCapsule: CapsuleButtonStyle { CapsuleButtonStyle(kind: .glass) }
}

#Preview {
    VStack(spacing: 12) {
        HStack {
            Button("Batal") {}.buttonStyle(.secondaryCapsule)
            Button("Simpan & proses", systemImage: "sparkles") {}.buttonStyle(.primaryCapsule)
        }
        HStack {
            Button("Tandai", systemImage: "flag") {}.buttonStyle(.glassCapsule)
            Button("Stop", systemImage: "stop.fill") {}.buttonStyle(.lightCapsule)
        }
        .padding()
        .background(MColor.brand700)
    }
    .padding()
}
