import SwiftUI

/// Tujuan saat kartu di Riwayat diketuk, sesuai status (design-handoff.md bagian 9):
/// selesai → 06 Detail, lainnya → 05 Memproses atau 13 Proses gagal.
struct MeetingDestinationView: View {
    let meeting: Meeting

    var body: some View {
        switch meeting.status {
        case .done:
            // TODO(UI): ganti dengan MeetingDetailView (layar 06–08).
            ContentUnavailableView("Detail meeting", systemImage: "doc.text", description: Text("Ringkasan, action items, transkrip, dan MoM menyusul."))
                .navigationTitle(meeting.title)
                .navigationBarTitleDisplayMode(.inline)
                .screenBackground(MBackground.light)
        case .recorded, .queued, .processing, .failed:
            ProcessingView(meeting: meeting)
        }
    }
}
