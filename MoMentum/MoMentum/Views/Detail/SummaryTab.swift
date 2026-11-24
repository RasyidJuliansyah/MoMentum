import SwiftUI

/// Tab Ringkasan (layar 06): kartu ringkasan lalu cuplikan action items.
struct SummaryTab: View {
    let content: MeetingDetailContent
    let onShowAllActionItems: () -> Void

    private let previewCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: MSpace.md) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Ringkasan", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MColor.brand700)
                if content.summaryParagraphs.isEmpty {
                    Text("Ringkasan belum tersedia.")
                        .font(.subheadline)
                        .foregroundStyle(MColor.n600)
                } else {
                    ForEach(content.summaryParagraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.subheadline)
                            .foregroundStyle(MColor.n900)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                // TODO(UI): chip "⚑ 2 momen ditandai ikut jadi konteks" setelah Meeting menyimpan penanda (PLAN-logic.md L1.1).
            }
            .padding(MSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MColor.n0.opacity(0.9), in: .rect(cornerRadius: 22))
            .shadow(color: MColor.brand900.opacity(0.06), radius: 12, y: 4)

            HStack(alignment: .firstTextBaseline) {
                Text("Action items")
                    .font(.title3.bold())
                    .foregroundStyle(MColor.n900)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if content.actionItems.count > previewCount {
                    Button("Lihat semua (\(content.actionItems.count))", action: onShowAllActionItems)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(MColor.brand700)
                }
            }
            .padding(.top, MSpace.xs)

            ActionItemsCard(content: content, items: Array(content.actionItems.prefix(previewCount)))
        }
    }
}

/// Kartu daftar action item, dipakai di tab Ringkasan (cuplikan) dan tab Action items (penuh).
struct ActionItemsCard: View {
    let content: MeetingDetailContent
    let items: [ActionItemContent]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if items.isEmpty {
                Text("Belum ada action item.")
                    .font(.subheadline)
                    .foregroundStyle(MColor.n600)
                    .padding(.vertical, 10)
            }
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Divider()
                }
                ActionItemRow(item: item, picOrder: item.pic.flatMap { content.speaker(named: $0)?.order })
            }
        }
        .padding(.horizontal, MSpace.md)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MColor.n0.opacity(0.9), in: .rect(cornerRadius: 22))
        .shadow(color: MColor.brand900.opacity(0.06), radius: 12, y: 4)
    }
}
