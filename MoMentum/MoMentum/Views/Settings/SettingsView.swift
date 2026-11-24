import SwiftUI

/// Placeholder layar 09 Pengaturan. Dibangun di tugas UI berikutnya.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Pengaturan", systemImage: "gearshape", description: Text("Layar pengaturan menyusul."))
                .navigationTitle("Pengaturan")
                .screenBackground(MBackground.light)
        }
    }
}

#Preview {
    SettingsView()
}
