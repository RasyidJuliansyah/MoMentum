import SwiftData
import SwiftUI

/// Layar 04 Riwayat (Figma node 14:178). Kalau belum ada meeting sama sekali, tampil state kosong 12.
struct HistoryView: View {
    var onStartRecording: () -> Void = {}

    @Query(sort: \Meeting.createdAt, order: .reverse) private var meetings: [Meeting]
    @Environment(MeetingProcessor.self) private var processor
    @State private var filter: HistoryFilter = .all
    @State private var query = ""
    @State private var pendingDelete: Meeting?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if meetings.isEmpty {
                    HistoryEmptyView(onStartRecording: onStartRecording)
                } else {
                    meetingList
                }
            }
            // Figma menampilkan kolom cari juga saat kosong (layar 12).
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cari kata di semua meeting")
            .navigationTitle("Riwayat")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // TODO(UI): belum ada requirement filter tanggal di PRD. Tombol dipasang sesuai desain.
                    Button("Pilih tanggal", systemImage: "calendar") {}
                }
            }
            .navigationDestination(for: Meeting.self) { meeting in
                MeetingDestinationView(meeting: meeting)
            }
            .screenBackground(MBackground.light)
            .alert(
                "Hapus meeting ini?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                presenting: pendingDelete
            ) { meeting in
                Button("Hapus", role: .destructive) {
                    MeetingDeleter.delete(meeting, in: modelContext)
                    pendingDelete = nil
                }
                Button("Batal", role: .cancel) { pendingDelete = nil }
            } message: { meeting in
                Text("\"\(meeting.title)\" dan rekamannya di iPhone akan dihapus permanen.")
            }
        }
    }

    private var meetingList: some View {
        let sections = HistoryGrouping.sections(for: meetings, filter: filter, query: query)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: MSpace.sm) {
                filterChips
                    .padding(.bottom, MSpace.xs)

                if sections.isEmpty {
                    ContentUnavailableView(
                        "Tidak ada meeting",
                        systemImage: "magnifyingglass",
                        description: Text(query.isEmpty ? "Belum ada meeting di filter ini." : "Tidak ada judul yang cocok dengan \"\(query)\".")
                    )
                    .padding(.top, MSpace.xl)
                }

                ForEach(sections) { section in
                    Text(section.title)
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(MColor.n600)
                        .padding(.top, MSpace.sm)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(section.meetings) { meeting in
                        card(for: meeting)
                    }
                }
            }
            .padding(.horizontal, MSpace.screen)
            .padding(.bottom, MSpace.lg)
        }
    }

    private func card(for meeting: Meeting) -> some View {
        let content = MeetingCardContent(meeting: meeting, liveProgress: processor.progressByMeetingID[meeting.persistentModelID])
        return NavigationLink(value: meeting) {
            MeetingCard(content: content, onRetry: { retry(meeting) }, onDelete: { pendingDelete = meeting })
        }
        .buttonStyle(.plain)
        .contextMenu {
            if content.showsRetry {
                Button("Coba lagi", systemImage: "arrow.clockwise") { retry(meeting) }
            }
            if content.canDelete {
                Button("Hapus", systemImage: "trash", role: .destructive) { pendingDelete = meeting }
            }
        }
        .accessibilityActions {
            if content.showsRetry {
                Button("Coba lagi") { retry(meeting) }
            }
            if content.canDelete {
                Button("Hapus") { pendingDelete = meeting }
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: MSpace.xs) {
                ForEach(HistoryFilter.allCases) { option in
                    let isSelected = option == filter
                    Button(option.label) { filter = option }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isSelected ? MColor.n0 : MColor.n900)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isSelected ? MColor.n900 : MColor.n0.opacity(0.9), in: .capsule)
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func retry(_ meeting: Meeting) {
        processor.retry(meeting)
    }
}

#Preview("04 · Riwayat", traits: .sampleData) {
    HistoryView()
}

#Preview("12 · Riwayat kosong") {
    HistoryView()
        .modelContainer(for: Meeting.self, inMemory: true)
}
