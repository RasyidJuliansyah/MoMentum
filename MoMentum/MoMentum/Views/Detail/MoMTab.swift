import SwiftUI

/// Tab MoM (layar 08): pilihan Teks/Markdown lalu kartu MoM.
struct MoMTab: View {
    let document: MoMDocument
    @Binding var format: MoMFormat

    var body: some View {
        VStack(alignment: .leading, spacing: MSpace.sm) {
            HStack {
                Picker("Format", selection: $format) {
                    ForEach(MoMFormat.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                Spacer()
                // TODO(UI): edit MoM (requirement S) setelah format penyimpanan MoM disepakati dengan sesi Logic.
                Button {} label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MColor.n900)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(MColor.n0, in: .capsule)
                        .overlay(Capsule().strokeBorder(MColor.n200))
                }
                .buttonStyle(.plain)
                .disabled(true)
                ExportMoMButton(document: document)
            }

            Group {
                if format == .text {
                    structured
                } else {
                    Text(document.markdown())
                        .font(.footnote.monospaced())
                        .foregroundStyle(MColor.n900)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(MSpace.md + 2)
            .background(MColor.n0, in: .rect(cornerRadius: 22))
            .shadow(color: MColor.brand900.opacity(0.06), radius: 12, y: 4)
        }
    }

    private var structured: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MINUTES OF MEETING")
                    .font(.caption.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(MColor.brand700)
                Text(document.title)
                    .font(.title2.bold())
                    .foregroundStyle(MColor.n900)
            }

            Grid(alignment: .leading, horizontalSpacing: MSpace.md, verticalSpacing: 6) {
                infoRow("Tanggal", document.dateText)
                infoRow("Waktu", document.timeText)
                infoRow("Peserta", document.participantsText.isEmpty ? "-" : document.participantsText)
                infoRow("Notulis", document.notetaker)
            }
            .padding(MSpace.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MColor.n50, in: .rect(cornerRadius: 14))

            if !document.topics.isEmpty {
                section("Topik") {
                    ForEach(Array(document.topics.enumerated()), id: \.offset) { index, topic in
                        listRow(marker: "\(index + 1).", text: topic)
                    }
                }
            }
            if !document.decisions.isEmpty {
                section("Keputusan") {
                    ForEach(document.decisions, id: \.self) { listRow(marker: "•", text: $0) }
                }
            }
            if !document.actionItems.isEmpty {
                section("Action items") {
                    ForEach(document.actionItems) { item in
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.task)
                                .font(.footnote)
                                .foregroundStyle(MColor.n900)
                            Spacer(minLength: MSpace.xs)
                            Text([item.pic ?? ActionItemContent.unclearPIC, item.due].compactMap { $0 }.joined(separator: " · "))
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(item.pic == nil ? MColor.warn : MColor.brand700)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(MColor.n600)
            Text(value)
                .foregroundStyle(MColor.n900)
        }
        .font(.footnote)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MColor.n900)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func listRow(marker: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MSpace.xs) {
            Text(marker)
                .foregroundStyle(MColor.n600)
            Text(text)
                .foregroundStyle(MColor.n900)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.footnote)
    }
}
