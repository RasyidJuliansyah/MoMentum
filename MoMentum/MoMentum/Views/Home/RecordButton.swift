import SwiftUI

/// Tombol rekam utama di Beranda: lingkaran brand700 dengan halo putih di sekelilingnya.
struct RecordButton: View {
    let action: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.45))
                .frame(width: 140, height: 140)
                .shadow(color: MColor.brand900.opacity(0.08), radius: 20, y: 8)
            Circle()
                .fill(.white.opacity(0.6))
                .frame(width: 104, height: 104)

            Button(action: action) {
                Image(systemName: "mic.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(MColor.brand700, in: .circle)
                    .shadow(color: MColor.brand700.opacity(0.35), radius: 14, y: 8)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mulai merekam")
        }
    }
}

#Preview {
    RecordButton {}
        .padding(40)
        .screenBackground(MBackground.deep)
}
