import AVFAudio
import SwiftUI

/// Root app: onboarding di peluncuran pertama, lalu TabView utama.
/// Lihat alur navigasi di docs/design-handoff.md bagian 9.
///
/// Izin mikrofon dicek setiap app dibuka, bukan hanya saat onboarding pertama: kalau belum diizinkan,
/// layar 11 muncul dulu sebelum TabView. Tanpa ini, user yang sudah lewat onboarding (atau memasang
/// ulang app) bisa sampai ke layar rekam tanpa pernah diminta izin.
struct ContentView: View {
    @AppStorage(AppStorageKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var microphonePermission = AVAudioApplication.shared.recordPermission
    /// "Lanjut tanpa mikrofon" hanya berlaku sampai app ditutup; saat dibuka lagi layar izin muncul lagi.
    @State private var skippedMicrophoneThisSession = false

    init() {
        #if DEBUG
        UITestSupport.resetDefaultsIfRequested()
        #endif
    }

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView {
                    hasCompletedOnboarding = true
                    finishMicrophoneStep()
                }
            } else if LaunchGate.needsMicrophoneStep(permission: microphonePermission, skipped: skippedMicrophoneThisSession) {
                NavigationStack {
                    OnboardingMicView(showsPageDots: false, onFinish: finishMicrophoneStep)
                }
            } else {
                MainTabView()
            }
        }
        // Kembali dari Pengaturan iOS: baca ulang izin supaya layar ikut berubah.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { microphonePermission = AVAudioApplication.shared.recordPermission }
        }
        // Desain belum punya mode gelap (design-handoff.md bagian 10).
        .preferredColorScheme(.light)
        #if DEBUG
        .uiTestModelContainer()
        #endif
    }

    private func finishMicrophoneStep() {
        microphonePermission = AVAudioApplication.shared.recordPermission
        skippedMicrophoneThisSession = true
    }
}

enum LaunchGate {
    static func needsMicrophoneStep(permission: AVAudioApplication.recordPermission, skipped: Bool) -> Bool {
        #if DEBUG
        // UI test di simulator: izin mikrofon tidak bisa diatur, jangan halangi tes lain.
        if UITestSupport.requestedSeed != nil { return false }
        #endif
        return permission != .granted && !skipped
    }
}

#Preview(traits: .sampleData) {
    ContentView()
}
