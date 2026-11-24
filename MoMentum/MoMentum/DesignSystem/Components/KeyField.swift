import SwiftUI

/// Kolom API key: tersamar (4 karakter terakhir terlihat) saat tidak diedit, `SecureField` saat diedit,
/// dengan tombol Tempel bawaan sistem (tanpa prompt izin clipboard).
struct KeyField: View {
    let label: String
    @Binding var key: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "key")
                .font(.footnote)
                .foregroundStyle(MColor.n600)
                .accessibilityHidden(true)

            ZStack(alignment: .leading) {
                SecureField(label, text: $key, prompt: Text("Tempel API key di sini"))
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .opacity(isFocused || key.isEmpty ? 1 : 0)
                if !isFocused, !key.isEmpty {
                    Text(KeyMask.masked(key))
                        .monospaced()
                        .foregroundStyle(MColor.n900)
                        .lineLimit(1)
                        .onTapGesture { isFocused = true }
                        .accessibilityHidden(true)
                }
            }
            .font(.subheadline)

            if key.isEmpty {
                PasteButton(payloadType: String.self) { strings in
                    key = strings.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                }
                .labelStyle(.titleOnly)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .tint(MColor.brand700)
            } else if !isFocused {
                Label("Terisi", systemImage: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MColor.success)
                    .labelStyle(CompactLabelStyle())
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .background(MColor.n0, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isFocused ? MColor.brand700 : MColor.n200, lineWidth: isFocused ? 1.5 : 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
        .accessibilityValue(key.isEmpty ? "Kosong" : "Terisi")
    }
}
