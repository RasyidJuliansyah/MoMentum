import SwiftUI

/// Baris action item (Figma: Action Item Row di layar 06). PIC kosong tampil sebagai chip "PIC belum jelas".
struct ActionItemRow: View {
    let item: ActionItemContent
    /// Urutan speaker untuk warna avatar PIC, kalau PIC cocok dengan speaker.
    var picOrder: Int?

    var body: some View {
        HStack(alignment: .top, spacing: MSpace.sm) {
            // TODO(UI): jadikan checkbox setelah ActionItem punya status selesai (lihat handover 3a).
            Circle()
                .strokeBorder(MColor.n400, lineWidth: 1.5)
                .frame(width: 22, height: 22)
                .padding(.top, 1)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(item.task)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MColor.n900)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: MSpace.xs) {
                    picChip
                    if let due = item.due {
                        Text("Tenggat \(due)")
                            .font(.caption)
                            .foregroundStyle(MColor.n600)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var picChip: some View {
        if let pic = item.pic {
            HStack(spacing: 5) {
                SpeakerAvatar(text: String(pic.prefix(1)).uppercased(), order: picOrder ?? 0, size: 18)
                Text(pic)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MColor.n900)
            }
            .padding(.leading, 3)
            .padding(.trailing, 8)
            .padding(.vertical, 3)
            .background(MColor.n50, in: .capsule)
            .overlay(Capsule().strokeBorder(MColor.n200))
        } else {
            Text(ActionItemContent.unclearPIC)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MColor.warn)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MColor.warnBg, in: .capsule)
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        ActionItemRow(item: ActionItemContent(task: "Buat generator QR dinamis (rotasi 30 detik)", pic: "Bayu", due: "28 Nov"), picOrder: 2)
        Divider()
        ActionItemRow(item: ActionItemContent(task: "Cek kebijakan HP 3 sekolah pilot", pic: nil, due: nil))
    }
    .padding()
}
