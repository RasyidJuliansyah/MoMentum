import SwiftUI

/// Layar 12 Riwayat kosong (Figma node 18:539).
struct HistoryEmptyView: View {
    let onStartRecording: () -> Void

    var body: some View {
        VStack(spacing: MSpace.md) {
            Spacer()
            ZStack {
                Circle()
                    .fill(MColor.n0.opacity(0.45))
                    .frame(width: 152, height: 152)
                    .shadow(color: MColor.brand900.opacity(0.06), radius: 20, y: 8)
                Circle()
                    .fill(MColor.n0.opacity(0.7))
                    .frame(width: 112, height: 112)
                Image(systemName: "waveform")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(MColor.n0)
                    .frame(width: 76, height: 76)
                    .background(MColor.brand500, in: .circle)
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Belum ada meeting")
                    .font(.title3.bold())
                    .foregroundStyle(MColor.n900)
                Text("Rekam meeting pertamamu. Transkrip, ringkasan, dan MoM akan muncul di sini.")
                    .font(.footnote)
                    .foregroundStyle(MColor.n600)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, MSpace.xs)

            Button(action: onStartRecording) {
                Label("Mulai rekam", systemImage: "mic.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MColor.n0)
                    .padding(.horizontal, MSpace.lg)
                    .frame(minHeight: 50)
                    .background(MColor.n900, in: .capsule)
            }
            .buttonStyle(.plain)
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
