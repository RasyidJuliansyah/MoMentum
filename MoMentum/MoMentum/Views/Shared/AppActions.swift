import SwiftUI

/// Aksi lintas layar yang dipasang `MainTabView` lewat environment,
/// misalnya tombol "Cek API key" di layar 13 yang pindah ke tab Pengaturan.
struct OpenSettingsAction {
    var action: () -> Void = {}

    func callAsFunction() {
        action()
    }
}

extension EnvironmentValues {
    @Entry var openSettings = OpenSettingsAction()
}
