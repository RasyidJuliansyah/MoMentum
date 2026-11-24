import SwiftUI

/// Sheet pasang atau ganti API key dari Pengaturan.
struct KeyEditorSheet: View {
    let kind: APIKeyKind
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var key = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: MSpace.sm) {
                Label(kind.providerName, systemImage: kind.systemImage)
                    .font(.subheadline)
                    .foregroundStyle(MColor.n600)
                KeyField(label: "API key \(kind.title)", key: $key)
                Label("Disimpan di iOS Keychain, tidak pernah ditanam di kode.", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(MColor.n600)
                    .labelStyle(CompactLabelStyle())
                Spacer()
            }
            .padding(MSpace.lg)
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan", systemImage: "checkmark") {
                        APIKeyStore.save(key, for: kind)
                        onSaved()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
