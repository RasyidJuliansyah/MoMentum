import SwiftUI

/// Sheet "Isi judul, agenda & istilah dulu" dari Beranda, sebelum mulai merekam.
/// Belum ada layar Figma khusus; memakai form yang sama dengan layar 03.
struct MeetingContextSheet: View {
    let initial: MeetingContextDraft
    let onSave: (MeetingContextDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = MeetingContextDraft()

    var body: some View {
        NavigationStack {
            ScrollView {
                MeetingContextForm(draft: $draft)
                    .padding(MSpace.lg)
            }
            .navigationTitle("Konteks meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan", systemImage: "checkmark") {
                        onSave(draft)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear { draft = initial }
        .presentationDetents([.large])
    }
}

#Preview {
    MeetingContextSheet(initial: MeetingContextDraft()) { _ in }
}
