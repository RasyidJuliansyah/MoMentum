#if DEBUG
import SwiftData
import SwiftUI

/// Khusus UI test, hanya di build DEBUG. Aktif lewat argumen peluncuran `-uiTestData empty` atau
/// `-uiTestData sample`. Database diganti versi in-memory, jadi data asli di perangkat tidak tersentuh.
enum UITestSupport {
    enum Seed: String {
        case empty
        case sample
    }

    static let requestedSeed: Seed? = UserDefaults.standard.string(forKey: "uiTestData").flatMap(Seed.init)

    /// Argumen `-uiTestResetDefaults`: hapus status onboarding dan nama yang tersimpan, supaya UI test
    /// onboarding selalu mulai dari awal. Tidak memakai `-hasCompletedOnboarding NO` karena argumen
    /// peluncuran selalu menang atas nilai yang ditulis app, jadi onboarding tidak pernah terlihat selesai.
    static func resetDefaultsIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-uiTestResetDefaults") else { return }
        for key in [AppStorageKey.hasCompletedOnboarding, AppStorageKey.userName] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    static let container: ModelContainer? = {
        guard let seed = requestedSeed else { return nil }
        let container = try? ModelContainer(
            for: Meeting.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        if seed == .sample, let container {
            for meeting in Meeting.previewSamples() {
                container.mainContext.insert(meeting)
            }
        }
        return container
    }()
}

extension View {
    /// Pakai database in-memory kalau app dijalankan oleh UI test dengan `-uiTestData`.
    @ViewBuilder
    func uiTestModelContainer() -> some View {
        if let container = UITestSupport.container {
            modelContainer(container)
        } else {
            self
        }
    }
}
#endif
