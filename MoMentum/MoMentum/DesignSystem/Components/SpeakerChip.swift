import SwiftUI

/// Avatar bulat speaker. Warna mengikuti urutan kemunculan; speaker tanpa nama abu-abu.
struct SpeakerAvatar: View {
    let text: String
    let order: Int
    var isNamed = true
    var size: CGFloat = 24

    static let palette = [MColor.brand700, MColor.info, MColor.warn, MColor.success, MColor.brand500, MColor.danger]

    var body: some View {
        Text(text)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(MColor.n0)
            .frame(width: size, height: size)
            .background(isNamed ? Self.palette[order % Self.palette.count] : MColor.n400, in: .circle)
            .accessibilityHidden(true)
    }
}

/// Chip speaker di tab Transkrip (Figma: Speaker Chip). Speaker tanpa nama bergaris putus-putus `warn`.
struct SpeakerChip: View {
    let speaker: SpeakerInfo

    var body: some View {
        HStack(spacing: 6) {
            SpeakerAvatar(text: speaker.avatarText, order: speaker.order, isNamed: speaker.isNamed)
            Text(speaker.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(speaker.isNamed ? MColor.n900 : MColor.warn)
            Image(systemName: "pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(speaker.isNamed ? MColor.n600 : MColor.warn)
        }
        .padding(.leading, 5)
        .padding(.trailing, 10)
        .padding(.vertical, 5)
        .background(speaker.isNamed ? MColor.n50 : MColor.warnBg, in: .capsule)
        .overlay {
            if speaker.isNamed {
                Capsule().strokeBorder(MColor.n200)
            } else {
                Capsule().strokeBorder(MColor.warn, style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(speaker.isNamed ? "\(speaker.label), ganti nama" : "\(speaker.label) belum diberi nama, ganti nama")
    }
}
