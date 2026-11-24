import SwiftData
import SwiftUI

/// Layar 04 Riwayat (Figma node 14:178). Kalau belum ada meeting sama sekali, tampil state kosong 12.
struct HistoryView: View {
    var onStartRecording: () -> Void = {}

    @Query(sort: \Meeting.createdAt, order: .reverse) private var meetings: [Meeting]
    @State private var filter: HistoryFilter = .all
    @State private var query = ""

    var body: some View {
        NavigationStack {
            Group {
                if meetings.isEmpty {
                    HistoryEmptyView(onStartRecording: onStartRecording)
                } else {
                    meetingList
                        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cari kata di semua meeting")
                }
            }
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
        let content = MeetingCardContent(meeting: meeting)
        return NavigationLink(value: meeting) {
            MeetingCard(content: content, onRetry: { retry(meeting) })
        }
        .buttonStyle(.plain)
        .accessibilityActions {
            if content.showsRetry {
                Button("Coba lagi") { retry(meeting) }
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
        // TODO(UI): panggil MeetingProcessor.retry(_:) setelah tersedia (PLAN-logic.md L6.3).
    }
}

#Preview("04 · Riwayat", traits: .sampleData) {
    HistoryView()
}

#Preview("12 · Riwayat kosong") {
    HistoryView()
        .modelContainer(for: Meeting.self, inMemory: true)
}
