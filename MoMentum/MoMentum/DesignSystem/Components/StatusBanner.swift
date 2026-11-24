import SwiftUI

/// Banner status (Figma: Banner di layar 14 dan 15). Kartu putih, ikon putih dalam lingkaran berwarna solid,
/// judul + keterangan.
struct StatusBanner: View {
    enum Kind {
        case info
        case warning
        case danger

        var colors: (fg: Color, bg: Color) {
            switch self {
            case .info: (MColor.info, MColor.infoBg)
            case .warning: (MColor.warn, MColor.warnBg)
            case .danger: (MColor.danger, MColor.dangerBg)
            }
        }
    }

    let kind: Kind
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: MSpace.sm) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MColor.n0)
                .frame(width: 36, height: 36)
                .background(kind.colors.fg, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MColor.n900)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(MColor.n600)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(MColor.n0, in: .rect(cornerRadius: 20))
        .shadow(color: MColor.brand900.opacity(0.08), radius: 14, y: 6)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        StatusBanner(kind: .warning, systemImage: "phone", title: "Dijeda karena telepon", message: "Rekaman lanjut otomatis setelah telepon selesai.")
        StatusBanner(kind: .danger, systemImage: "exclamationmark.triangle", title: "Ruang hampir penuh", message: "Sisa ruang cukup untuk ± 20 menit lagi.")
    }
    .padding()
    .screenBackground(MBackground.light)
}
