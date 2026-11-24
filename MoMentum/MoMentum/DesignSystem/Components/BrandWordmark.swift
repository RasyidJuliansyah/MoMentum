import SwiftUI

/// Logo wordmark: ikon `waveform` + teks "MoMentum" dengan "MoM" berwarna brand700.
struct BrandWordmark: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform")
                .foregroundStyle(MColor.brand700)
            Text("\(Text("MoM").foregroundStyle(MColor.brand700))entum")
                .foregroundStyle(MColor.brand900)
        }
        .font(.title3.weight(.bold))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("MoMentum")
    }
}

#Preview {
    BrandWordmark()
        .padding()
}
