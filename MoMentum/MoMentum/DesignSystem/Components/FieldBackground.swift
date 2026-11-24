import SwiftUI

extension View {
    /// Latar input teks gaya MoMentum: isi `n50`, garis `n200`, radius 16.
    func fieldBackground() -> some View {
        padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 48)
            .background(MColor.n50, in: .rect(cornerRadius: MRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: MRadius.md)
                    .strokeBorder(MColor.n200)
            }
    }
}
