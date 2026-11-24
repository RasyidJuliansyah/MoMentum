import SwiftUI

/// Kotak catatan kecil berlatar hijau muda (Figma: catatan bawah di layar 05 dan 13).
struct NoteBox: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(MColor.brand700)
                .padding(.top, 1)
            Text(text)
                .font(.footnote)
                .foregroundStyle(MColor.n900)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(MColor.brand50, in: .rect(cornerRadius: MRadius.md))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NoteBox(systemImage: "checkmark", text: "Rekaman tetap aman di iPhone. Coba lagi hanya mengirim segmen 7–11.")
        .padding()
}
