import SwiftUI

enum AppTab: Hashable {
    case home
    case history
    case settings
}

/// Tab bar native iOS 26 (sudah Liquid Glass). Desain custom di Figma hanya acuan isi.
struct MainTabView: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Beranda", systemImage: "house", value: AppTab.home) {
                HomeView(onOpenSettings: { selection = .settings })
            }
            Tab("Riwayat", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView()
            }
            Tab("Pengaturan", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
            }
        }
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
}
