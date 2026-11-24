import SwiftUI

/// Isian judul, agenda, dan istilah khusus (bagian tengah layar 03).
struct MeetingContextForm: View {
    @Binding var draft: MeetingContextDraft

    @State private var isAddingTerm = false
    @State private var newTerm = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            field("Judul meeting") {
                TextField("Judul meeting", text: $draft.title, prompt: Text(MeetingContextDraft.defaultTitle(for: .now)))
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.next)
            }

            field("Agenda (opsional)") {
                TextField("Agenda", text: $draft.agenda, prompt: Text("Contoh: review sprint, roadmap Q1"), axis: .vertical)
                    .lineLimit(1...3)
            }

            VStack(alignment: .leading, spacing: MSpace.xs) {
                fieldLabel("Istilah khusus")
                FlowLayout(spacing: MSpace.xs, lineSpacing: MSpace.xs) {
                    ForEach(draft.terms, id: \.self) { term in
                        TermChip(term: term)
                            .contextMenu {
                                Button("Hapus", systemImage: "trash", role: .destructive) {
                                    draft.removeTerm(term)
                                }
                            }
                    }
                    Button {
                        newTerm = ""
                        isAddingTerm = true
                    } label: {
                        Label("Tambah", systemImage: "plus")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(MColor.n900)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(MColor.n0, in: .capsule)
                            .overlay(Capsule().strokeBorder(MColor.n200))
                    }
                    .buttonStyle(.plain)
                }
                Text("Dipakai sebagai keyword hint STT supaya istilah tidak salah tulis.")
                    .font(.caption)
                    .foregroundStyle(MColor.n400)
            }
        }
        .alert("Tambah istilah", isPresented: $isAddingTerm) {
            TextField("Contoh: SNBP", text: $newTerm)
                .textInputAutocapitalization(.characters)
            Button("Batal", role: .cancel) {}
            Button("Tambah") { draft.addTerm(newTerm) }
        } message: {
            Text("Nama produk, singkatan, atau nama orang yang sering muncul di meeting.")
        }
    }

    /// Label di atas kolom. Untuk VoiceOver dan UI test, label dipasang ke kolomnya langsung.
    private func field(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: MSpace.xs) {
            fieldLabel(label)
                .accessibilityHidden(true)
            content()
                .font(.body)
                .foregroundStyle(MColor.n900)
                .accessibilityLabel(label)
                .fieldBackground()
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(MColor.n600)
    }
}

private struct TermChip: View {
    let term: String

    var body: some View {
        Text(term)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(MColor.brand700)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(MColor.brand100, in: .capsule)
            .accessibilityHint("Tekan lama untuk menghapus")
    }
}

#Preview {
    @Previewable @State var draft = MeetingContextDraft(
        title: "Weekly Sync Product",
        agenda: "Review sprint, roadmap Q1, isu SNBP",
        terms: ["SNBP", "TKA", "LMS IFP"]
    )
    MeetingContextForm(draft: $draft)
        .padding()
}
