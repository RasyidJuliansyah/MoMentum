import SwiftUI

/// Sheet ganti nama speaker (layar 07, Figma node 16:297).
struct RenameSpeakerSheet: View {
    let speaker: SpeakerInfo
    let onSave: (_ name: String, _ regenerateSummary: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var regenerateSummary = true
    @State private var contentHeight: CGFloat = 520
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: MSpace.md) {
            HStack(spacing: MSpace.sm) {
                SpeakerAvatar(text: speaker.avatarText, order: speaker.order, isNamed: speaker.isNamed, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ganti nama \(speaker.label)")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(MColor.n900)
                    Text("Muncul \(speaker.occurrences) kali · pertama di \(MFormat.clock(Double(speaker.firstStartMs) / 1000))")
                        .font(.footnote)
                        .foregroundStyle(MColor.n600)
                }
            }

            // TODO(UI): tombol putar potongan audio setelah ada pemutar audio di Services.
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundStyle(MColor.n600)
                Text(speaker.firstQuote)
                    .font(.subheadline)
                    .foregroundStyle(MColor.n900)
                    .lineLimit(3)
            }
            .padding(MSpace.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MColor.n50, in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: MSpace.xs) {
                Text("Nama")
                    .font(.subheadline)
                    .foregroundStyle(MColor.n600)
                    .accessibilityHidden(true)
                TextField("Nama", text: $name, prompt: Text("Contoh: Pak Hendra"))
                    .font(.body)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .accessibilityLabel("Nama")
                    .padding(.horizontal, 14)
                    .frame(minHeight: 52)
                    .background(MColor.n0, in: .rect(cornerRadius: MRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: MRadius.md).strokeBorder(MColor.brand700, lineWidth: 1.5))
            }
            // TODO(UI): baris "Saran:" dari nama yang pernah dipakai di meeting lain, setelah D3 diputuskan.

            Label("Berlaku di seluruh transkrip, action items, dan MoM", systemImage: "checkmark")
                .font(.footnote)
                .foregroundStyle(MColor.n600)

            Toggle(isOn: $regenerateSummary) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate ulang ringkasan")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MColor.n900)
                    Text("Tanpa transkripsi ulang")
                        .font(.caption)
                        .foregroundStyle(MColor.n600)
                }
            }
            .tint(MColor.brand700)
            .padding(MSpace.sm)
            .background(MColor.n50, in: .rect(cornerRadius: MRadius.md))

            HStack(spacing: 10) {
                Button("Batal") { dismiss() }
                    .buttonStyle(.secondaryCapsule)
                Button("Simpan nama") {
                    onSave(trimmedName, regenerateSummary)
                    dismiss()
                }
                .buttonStyle(.primaryCapsule)
                .disabled(trimmedName.isEmpty)
            }
        }
        .padding(MSpace.lg)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        .onAppear {
            name = speaker.isNamed ? speaker.label : ""
            isNameFocused = true
        }
        .presentationDetents([.height(contentHeight), .large])
        .presentationCornerRadius(MRadius.xl)
    }
}
