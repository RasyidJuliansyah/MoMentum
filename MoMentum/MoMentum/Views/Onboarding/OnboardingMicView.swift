import AVFAudio
import SwiftUI
import UIKit

/// Layar 11 Onboarding · Izin mikrofon (Figma node 18:471).
struct OnboardingMicView: View {
    let onFinish: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var permission = AVAudioApplication.shared.recordPermission

    var body: some View {
        ScrollView {
            VStack(spacing: MSpace.lg) {
                HeroIcon(systemImage: "mic")
                    .padding(.top, MSpace.xs)

                VStack(spacing: MSpace.xs) {
                    Text("Izinkan akses mikrofon")
                        .font(.title.bold())
                        .foregroundStyle(MColor.n900)
                    Text("Dibutuhkan untuk merekam meeting tatap muka, termasuk saat layar terkunci.")
                        .font(.subheadline)
                        .foregroundStyle(MColor.n600)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 14) {
                    point("lock", "Rekaman disimpan di iPhone", "Audio baru dikirim ke STT saat diproses")
                    point("cloud", "Tanpa server MoMentum", "App memanggil penyedia langsung dengan key-mu")
                    point("person.2", "Beri tahu peserta", "Sampaikan di awal bahwa meeting direkam")
                }
                .padding(MSpace.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: MRadius.lg))
            }
            .padding(.horizontal, MSpace.screen)
            .padding(.bottom, MSpace.lg)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: MSpace.sm) {
                if permission == .denied {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    } label: {
                        Label("Buka Pengaturan iOS", systemImage: "gearshape")
                    }
                    .buttonStyle(.primaryCapsule)
                    Button("Lanjut tanpa mikrofon", action: onFinish)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MColor.n0)
                } else {
                    Button(action: requestPermission) {
                        Label("Izinkan mikrofon", systemImage: "mic")
                    }
                    .buttonStyle(.primaryCapsule)
                    Text("Kalau sudah ditolak, buka Pengaturan iOS › MoMentum")
                        .font(.caption)
                        .foregroundStyle(MColor.n0.opacity(0.85))
                }
            }
            .padding(.horizontal, MSpace.screen)
            .padding(.bottom, MSpace.xs)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PageDots(count: 2, current: 1)
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .screenBackground(MBackground.deep)
    }

    private func point(_ systemImage: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: MSpace.sm) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(MColor.brand700)
                .frame(width: 34, height: 34)
                .background(MColor.brand50, in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MColor.n900)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(MColor.n600)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func requestPermission() {
        Task {
            let granted = await AVAudioApplication.requestRecordPermission()
            permission = AVAudioApplication.shared.recordPermission
            if granted { onFinish() }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingMicView {}
    }
}
