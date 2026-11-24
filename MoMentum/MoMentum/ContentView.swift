import SwiftUI

/// Root app: onboarding sekali di peluncuran pertama, lalu TabView utama.
/// Lihat alur navigasi di docs/design-handoff.md bagian 9.
struct ContentView: View {
    @AppStorage(AppStorageKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    init() {
        #if DEBUG
        UITestSupport.resetDefaultsIfRequested()
        #endif
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        // Desain belum punya mode gelap (design-handoff.md bagian 10).
        .preferredColorScheme(.light)
        #if DEBUG
        .uiTestModelContainer()
        #endif
    }
}

#Preview(traits: .sampleData) {
    ContentView()
}
