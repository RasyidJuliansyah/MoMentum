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

    var body: some View {
        TabView(selection: $selection) {
            Tab("Beranda", systemImage: "house", value: AppTab.home) {
                HomeView(
                    onRecord: { context in recordingRequest = RecordingRequest(context: context) },
                    onOpenSettings: { selection = .settings }
                )
            }
            Tab("Riwayat", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView(onStartRecording: { recordingRequest = RecordingRequest() })
            }
            Tab("Pengaturan", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
            }
        }
        .fullScreenCover(item: $recordingRequest) { request in
            RecordingView(context: request.context)
        }
        .environment(\.openSettings, OpenSettingsAction { selection = .settings })
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
}
