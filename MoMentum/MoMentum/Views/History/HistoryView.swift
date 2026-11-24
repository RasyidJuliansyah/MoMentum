import SwiftUI

/// Placeholder layar 04 Riwayat. Dibangun di tugas UI berikutnya.
struct HistoryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Riwayat", systemImage: "clock.arrow.circlepath", description: Text("Layar riwayat menyusul."))
                .navigationTitle("Riwayat")
                .screenBackground(MBackground.light)
        }
    }
}

#Preview {
    HistoryView()
}
