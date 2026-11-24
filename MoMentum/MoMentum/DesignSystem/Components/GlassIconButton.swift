import SwiftUI

/// Tombol ikon bulat 44 pt dengan Liquid Glass (Figma: IconButton glass).
struct GlassIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.medium))
                .foregroundStyle(MColor.n900)
                .frame(width: 44, height: 44)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    HStack {
        GlassIconButton(systemName: "bell", accessibilityLabel: "Notifikasi") {}
        GlassIconButton(systemName: "chevron.left", accessibilityLabel: "Kembali") {}
    }
    .padding(40)
    .screenBackground(MBackground.light)
}
