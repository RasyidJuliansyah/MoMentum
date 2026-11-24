import SwiftUI

/// Alur peluncuran pertama: 10 API key → 11 izin mikrofon → TabView (design-handoff.md bagian 9).
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var showsMicrophoneStep = false

    var body: some View {
        NavigationStack {
            OnboardingKeyView { showsMicrophoneStep = true }
                .navigationDestination(isPresented: $showsMicrophoneStep) {
                    OnboardingMicView(onFinish: onFinish)
                }
        }
    }
}

#Preview {
    OnboardingView {}
}
