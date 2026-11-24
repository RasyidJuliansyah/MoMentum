import SwiftUI

/// Placeholder layar 02 Merekam (fullScreenCover dari Beranda). Dibangun di tugas UI berikutnya.
struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContentUnavailableView {
            Label("Merekam", systemImage: "mic.fill")
        } description: {
            Text("Layar rekam menyusul.")
        } actions: {
            Button("Tutup") { dismiss() }
                .buttonStyle(.bordered)
        }
        .screenBackground(MBackground.deep)
    }
}

#Preview {
    RecordingView()
}
