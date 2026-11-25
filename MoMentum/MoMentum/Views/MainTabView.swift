import SwiftUI

enum AppTab: Hashable {
    case home
    case history
    case settings
}

/// Permintaan membuka layar rekam, dengan konteks meeting opsional dari Beranda.
struct RecordingRequest: Identifiable {
    let id = UUID()
    var context: MeetingContextDraft?
}

/// Tab bar native iOS 26 (sudah Liquid Glass). Desain custom di Figma hanya acuan isi.
/// Layar rekam dibuka dari sini supaya bisa dipicu dari Beranda maupun Riwayat kosong.
struct MainTabView: View {
    @State private var selection: AppTab = .home
    @State private var recordingRequest: RecordingRequest?
    @State private var isMicrophoneDenied = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        TabView(selection: $selection) {
            Tab("Beranda", systemImage: "house", value: AppTab.home) {
                HomeView(
                    onRecord: { context in startRecording(context) },
                    onOpenSettings: { selection = .settings }
                )
            }
            Tab("Riwayat", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView(onStartRecording: { startRecording(nil) })
            }
            Tab("Pengaturan", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
            }
        }
        .fullScreenCover(item: $recordingRequest) { request in
            RecordingView(context: request.context, onSaved: { selection = .history })
        }
        .alert("Mikrofon belum diizinkan", isPresented: $isMicrophoneDenied) {
            Button("Buka Pengaturan iPhone") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            Button("Nanti", role: .cancel) {}
        } message: {
            Text("MoMentum butuh mikrofon untuk merekam meeting. Aktifkan di Pengaturan iPhone › MoMentum › Mikrofon.")
        }
        .environment(\.openSettings, OpenSettingsAction { selection = .settings })
        .resumesPendingProcessing()
    }
}

extension MainTabView {
    /// Penjagaan tombol Mulai rekam: layar rekam baru dibuka setelah izin mikrofon ada.
    private func startRecording(_ context: MeetingContextDraft?) {
        Task {
            if await MicrophonePermission.ensureGranted() {
                recordingRequest = RecordingRequest(context: context)
            } else {
                isMicrophoneDenied = true
            }
        }
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
}
