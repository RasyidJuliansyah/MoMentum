import SwiftUI

/// Tab Transkrip (layar 07): chip speaker untuk ganti nama, lalu baris transkrip.
struct TranscriptTab: View {
    let content: MeetingDetailContent
    let onRename: (SpeakerInfo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MSpace.md) {
            if !content.speakers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Speaker di meeting ini · ketuk untuk ganti nama")
                        .font(.caption)
                        .foregroundStyle(MColor.n600)
                    FlowLayout(spacing: MSpace.xs, lineSpacing: MSpace.xs) {
                        ForEach(content.speakers) { speaker in
                            Button { onRename(speaker) } label: { SpeakerChip(speaker: speaker) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MColor.n0.opacity(0.9), in: .rect(cornerRadius: 22))
                .shadow(color: MColor.brand900.opacity(0.06), radius: 12, y: 4)
            }

            if content.transcript.isEmpty {
                Text("Transkrip belum tersedia.")
                    .font(.subheadline)
                    .foregroundStyle(MColor.n600)
            }

            LazyVStack(alignment: .leading, spacing: MSpace.md) {
                ForEach(content.transcript) { line in
                    row(line)
                }
            }
        }
    }

    private func row(_ line: TranscriptLine) -> some View {
        let speaker = content.speaker(named: line.speakerLabel)
        let isNamed = speaker?.isNamed ?? true
        return HStack(alignment: .top, spacing: 10) {
            SpeakerAvatar(text: speaker?.avatarText ?? "?", order: speaker?.order ?? 0, isNamed: isNamed, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(line.speakerLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isNamed ? MColor.brand700 : MColor.warn)
                    Text(MFormat.clock(Double(line.startMs) / 1000))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(MColor.n400)
                }
                Text(line.text)
                    .font(.subheadline)
                    .foregroundStyle(MColor.n900)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
