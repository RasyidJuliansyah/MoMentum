import SwiftUI

/// Kartu glass "Aktivitas minggu ini" berisi tiga angka.
struct WeeklyActivityCard: View {
    let stats: WeeklyStats

    var body: some View {
        VStack(alignment: .leading, spacing: MSpace.sm) {
            Label("Aktivitas minggu ini", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MColor.n900)

            HStack(spacing: 10) {
                StatTile(systemImage: "waveform", value: "\(stats.meetingCount)", label: "Meeting")
                StatTile(systemImage: "clock", value: MFormat.duration(stats.recordedSeconds), label: "Direkam")
                StatTile(systemImage: "doc.text", value: "\(stats.momReadyCount)", label: "MoM siap")
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: MRadius.lg))
    }
}

private struct StatTile: View {
    let systemImage: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MColor.n900)
                .frame(width: 28, height: 28)
                .background(.white, in: .circle)
                .padding(.bottom, 8)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(MColor.n900)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(MColor.n600)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.55), in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}

#Preview {
    WeeklyActivityCard(stats: WeeklyStats(meetingCount: 4, recordedSeconds: 33_600, momReadyCount: 3))
        .padding()
        .screenBackground(MBackground.deep)
}
