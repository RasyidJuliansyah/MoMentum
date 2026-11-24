import SwiftUI

/// Kartu "Status segmen" di layar 13: grid nomor segmen (selesai, gagal, menunggu) + legenda.
struct SegmentStatusGrid: View {
    let segments: [ProcessingContent.SegmentState]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: MSpace.xs), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: MSpace.sm) {
            Text("Status segmen")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MColor.n900)

            LazyVGrid(columns: columns, spacing: MSpace.xs) {
                ForEach(Array(segments.enumerated()), id: \.offset) { index, state in
                    cell(number: index + 1, state: state)
                }
            }

            HStack(spacing: 14) {
                legend(MColor.success, "\(count(.done)) selesai")
                legend(MColor.danger, "\(count(.failed)) gagal")
                legend(MColor.n400, "\(count(.pending)) menunggu")
            }
        }
        .padding(MSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MColor.n0.opacity(0.9), in: .rect(cornerRadius: 22))
        .shadow(color: MColor.brand900.opacity(0.06), radius: 12, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private func cell(number: Int, state: ProcessingContent.SegmentState) -> some View {
        let (foreground, background): (Color, Color) = switch state {
        case .done: (MColor.success, MColor.successBg)
        case .failed: (MColor.danger, MColor.dangerBg)
        case .pending: (MColor.n400, MColor.n100)
        }
        return Text("\(number)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(background, in: .rect(cornerRadius: MRadius.sm))
            .overlay {
                if state == .failed {
                    RoundedRectangle(cornerRadius: MRadius.sm).strokeBorder(MColor.danger, lineWidth: 1.5)
                }
            }
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(.caption)
                .foregroundStyle(MColor.n600)
        }
    }

    private func count(_ state: ProcessingContent.SegmentState) -> Int {
        segments.filter { $0 == state }.count
    }

    private var accessibilitySummary: String {
        var parts = ["Status segmen: \(count(.done)) selesai, \(count(.failed)) gagal, \(count(.pending)) menunggu"]
        let failed = segments.enumerated().filter { $0.element == .failed }.map { "\($0.offset + 1)" }
        if !failed.isEmpty {
            parts.append("Segmen gagal: \(failed.joined(separator: ", "))")
        }
        return parts.joined(separator: ". ")
    }
}

#Preview {
    SegmentStatusGrid(segments: ProcessingContent.previewFailed.segments)
        .padding()
        .screenBackground(MBackground.light)
}
