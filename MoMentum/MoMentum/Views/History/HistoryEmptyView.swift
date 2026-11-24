import SwiftUI

/// Layar 12 Riwayat kosong (Figma node 18:539). Dibangun dari gaya layar 04; cocokkan ulang ke Figma
/// setelah akses desain pulih.
struct HistoryEmptyView: View {
    let onStartRecording: () -> Void

    var body: some View {
        VStack(spacing: MSpace.md) {
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(MColor.brand700)
                .frame(width: 80, height: 80)
                .background(MColor.brand100, in: .circle)
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text("Belum ada meeting")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MColor.n900)
                Text("Rekam meeting tatap muka pertama. Transkrip, ringkasan, action items, dan MoM akan muncul di sini.")
                    .font(.subheadline)
                    .foregroundStyle(MColor.n600)
                    .multilineTextAlignment(.center)
            }
            Button(action: onStartRecording) {
                Label("Mulai merekam", systemImage: "mic.fill")
            }
            .buttonStyle(.primaryCapsule)
            .frame(maxWidth: 260)
            .padding(.top, MSpace.xs)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, MSpace.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HistoryEmptyView {}
        .screenBackground(MBackground.light)
}
