import SwiftUI

/// Kartu meeting (Figma: Meeting Card, node 14:114). Properti: judul, meta, badge status,
/// plus catatan, tombol coba lagi, dan bar progres yang muncul sesuai status.
struct MeetingCard: View {
    let content: MeetingCardContent
    var onRetry: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: MSpace.sm) {
            HStack(alignment: .top, spacing: MSpace.sm) {
                Image(systemName: "waveform")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MColor.n900)
                    .frame(width: 44, height: 44)
                    .background(MColor.brand50, in: .rect(cornerRadius: 12))
                // Lebar penuh supaya judul tidak dipaksa berbagi ruang dengan spacer lalu terlipat.
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.title)
                        .font(.headline)
                        .foregroundStyle(MColor.n900)
                        .lineLimit(2)
                    Text(content.meta)
                        .font(.footnote)
                        .foregroundStyle(MColor.n600)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                StatusBadge(status: content.status)
                    .fixedSize()
            }

            if let progress = content.progress {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: progress.fraction)
                        .tint(MColor.info)
                    Text(progress.label)
                        .font(.caption)
                        .foregroundStyle(MColor.n600)
                }
            }

            if content.note != nil || content.showsRetry {
                HStack(spacing: MSpace.xs) {
                    if let note = content.note {
                        Label(note.text, systemImage: note.systemImage)
                            .font(.footnote)
                            .foregroundStyle(MColor.n600)
                    }
                    Spacer(minLength: 0)
                    if content.showsRetry {
                        Button(action: onRetry) {
                            Label("Coba lagi", systemImage: "arrow.clockwise")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MColor.n0)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(MColor.n900, in: .capsule)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, content.showsRetry ? 0 : MSpace.sm)
                .padding(.vertical, content.showsRetry ? 0 : 10)
                .background(content.showsRetry ? Color.clear : MColor.n50, in: .rect(cornerRadius: MRadius.sm))
            }
        }
        .padding(14)
        .background(MColor.n0.opacity(0.9), in: .rect(cornerRadius: 22))
        .shadow(color: MColor.brand900.opacity(0.06), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: MSpace.sm) {
            ForEach(Meeting.previewSamples(), id: \.title) { meeting in
                MeetingCard(content: MeetingCardContent(meeting: meeting))
            }
        }
        .padding()
    }
    .screenBackground(MBackground.light)
}
