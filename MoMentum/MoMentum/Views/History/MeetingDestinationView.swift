import SwiftUI

/// Tujuan saat kartu di Riwayat diketuk, sesuai status (design-handoff.md bagian 9):
/// selesai → 06 Detail, lainnya → 05 Memproses atau 13 Proses gagal.
struct MeetingDestinationView: View {
    let meeting: Meeting

    var body: some View {
        switch meeting.status {
        case .done:
            MeetingDetailView(meeting: meeting)
        case .recorded, .queued, .processing, .failed:
            ProcessingView(meeting: meeting)
        }
    }
}
