import SwiftUI
import UIKit

/// Layar 06–08 Detail meeting (Figma node 14:445, 16:297, 16:440): satu layar dengan tab segmented.
struct MeetingDetailView: View {
    let meeting: Meeting

    @Environment(MeetingProcessor.self) private var processor
    @State private var tab: DetailTab = .summary
    @State private var momFormat: MoMFormat = .text
    @State private var renaming: SpeakerInfo?
    @State private var didCopy = false

    var body: some View {
        let content = MeetingDetailContent(meeting: meeting)
        let document = MoMDocument(meeting: meeting, content: content)

        ScrollView {
            VStack(alignment: .leading, spacing: MSpace.md) {
                if tab == .summary {
                    header(content)
                }
                Picker("Bagian", selection: $tab) {
                    ForEach(DetailTab.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)

                switch tab {
                case .summary:
                    SummaryTab(content: content) { tab = .actionItems }
                case .actionItems:
                    ActionItemsCard(content: content, items: content.actionItems)
                case .transcript:
                    TranscriptTab(content: content) { renaming = $0 }
                case .mom:
                    MoMTab(document: document, format: $momFormat)
                }
            }
            .padding(.horizontal, MSpace.screen)
            .padding(.bottom, MSpace.lg)
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar(text: tab == .mom ? momFormat.text(of: document) : document.plainText())
        }
        .navigationTitle(tab == .summary ? "" : meeting.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Lainnya", systemImage: "ellipsis") {
                    ShareLink(item: document.plainText()) {
                        Label("Bagikan MoM", systemImage: "square.and.arrow.up")
                    }
                    Button("Salin MoM", systemImage: "doc.on.doc") { copy(document.plainText()) }
                }
            }
        }
        .sheet(item: $renaming) { speaker in
            RenameSpeakerSheet(speaker: speaker) { name, regenerate in
                rename(speaker, to: name, regenerate: regenerate)
            }
        }
        .sensoryFeedback(.success, trigger: didCopy) { _, new in new }
        .screenBackground(MBackground.light)
    }

    private func header(_ content: MeetingDetailContent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: MSpace.xs) {
                StatusBadge(status: content.status)
                if let processed = content.processedText {
                    Text(processed)
                        .font(.caption)
                        .foregroundStyle(MColor.n600)
                }
            }
            Text(content.title)
                .font(.title.bold())
                .foregroundStyle(MColor.n900)
            HStack(spacing: 14) {
                Label(content.dateText, systemImage: "calendar")
                Label(content.durationText, systemImage: "clock")
                if content.participantCount > 0 {
                    Label("\(content.participantCount) peserta", systemImage: "person.2")
                }
            }
            .font(.footnote)
            .foregroundStyle(MColor.n600)
            .labelStyle(CompactLabelStyle())
        }
    }

    private func bottomBar(text: String) -> some View {
        HStack(spacing: 10) {
            if tab == .mom {
                Button { copy(text) } label: {
                    Label(didCopy ? "Tersalin" : "Salin teks", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.secondaryCapsule)
                ShareLink(item: text) {
                    Label("Bagikan", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.primaryCapsule)
            } else {
                Button { processor.regenerateSummary(meeting) } label: {
                    Label("Generate ulang", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.secondaryCapsule)
                ShareLink(item: text) {
                    Label("Bagikan MoM", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.primaryCapsule)
            }
        }
        .padding(MSpace.xs)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, MSpace.screen)
        .padding(.bottom, MSpace.xs)
    }

    /// `speaker.label` adalah nama tampil; cari label mentah ("Speaker 2") lewat `Meeting.speakers`.
    private func rename(_ speaker: SpeakerInfo, to name: String, regenerate: Bool) {
        guard !name.isEmpty else { return }
        let target = meeting.speakers.first { meeting.displayName(for: $0.label) == speaker.label }
        if let target {
            target.name = name
        } else {
            // Meeting lama tanpa model Speaker: buat dari label yang tampil.
            let created = Speaker(label: speaker.label, name: name)
            meeting.speakers.append(created)
        }
        if regenerate {
            processor.regenerateSummary(meeting)
        }
    }

    private func copy(_ text: String) {
        UIPasteboard.general.string = text
        didCopy = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            didCopy = false
        }
    }
}

/// Format MoM yang ditampilkan dan dibagikan.
enum MoMFormat: String, CaseIterable, Identifiable {
    case text
    case markdown

    var id: Self { self }
    var label: String { self == .text ? "Teks" : "Markdown" }

    func text(of document: MoMDocument) -> String {
        self == .text ? document.plainText() : document.markdown()
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var meeting = Meeting.previewSamples()[2]
    NavigationStack {
        MeetingDetailView(meeting: meeting)
    }
}
