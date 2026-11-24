import SwiftUI

/// Placeholder alur onboarding (layar 10 API key → 11 izin mikrofon). Dibangun di tugas UI berikutnya.
struct OnboardingView: View {
    let onFinish: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Onboarding", systemImage: "key")
        } description: {
            Text("Layar API key dan izin mikrofon menyusul.")
        } actions: {
            Button("Lewati untuk sekarang", action: onFinish)
                .buttonStyle(.borderedProminent)
        }
        .screenBackground(MBackground.deep)
    }
}

#Preview {
    OnboardingView {}
}
