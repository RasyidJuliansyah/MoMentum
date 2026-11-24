import SwiftUI

/// Tujuan saat kartu di Riwayat diketuk, sesuai status (design-handoff.md bagian 9):
/// selesai → 06 Detail, gagal → 13 Proses gagal, lainnya → 05 Memproses.
/// Ketiga layar itu masih placeholder dan dibangun di tugas UI berikutnya.
struct MeetingDestinationView: View {
    let meeting: Meeting

    var body: some View {
        Group {
            switch meeting.status {
            case .done:
                ContentUnavailableView("Detail meeting", systemImage: "doc.text", description: Text("Ringkasan, action items, transkrip, dan MoM menyusul."))
            case .failed:
                ContentUnavailableView("Proses gagal", systemImage: "exclamationmark.triangle", description: Text("Layar proses gagal dan coba lagi menyusul."))
            case .recorded, .queued, .processing:
                ContentUnavailableView("Memproses", systemImage: "sparkles", description: Text("Layar progres proses menyusul."))
            }
        }
        .navigationTitle(meeting.title)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground(MBackground.light)
    }
}
