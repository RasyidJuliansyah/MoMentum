import SwiftUI

/// Layar 10 Onboarding · API key (Figma node 18:396).
struct OnboardingKeyView: View {
    let onNext: () -> Void

    @State private var speechKey = APIKeyStore.key(for: .speechToText) ?? ""
    @State private var summaryKey = APIKeyStore.key(for: .summary) ?? ""

    var body: some View {
        ScrollView {
            VStack(spacing: MSpace.lg) {
                HStack {
                    BrandWordmark()
                    Spacer()
                    PageDots(count: 2, current: 0)
                }
                .padding(.top, MSpace.xs)

                HeroIcon(systemImage: "key")

                VStack(spacing: MSpace.xs) {
                    Text("Pasang API key dulu")
                        .font(.title.bold())
                        .foregroundStyle(MColor.n900)
                    Text("MoMentum memakai akun STT dan LLM milikmu sendiri. Biaya langsung tercatat di akunmu.")
                        .font(.subheadline)
                        .foregroundStyle(MColor.n600)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: MSpace.sm) {
                    keySection(.speechToText, vendor: "AssemblyAI", key: $speechKey)
                    keySection(.summary, vendor: nil, key: $summaryKey)
                    Label("Disimpan di iOS Keychain, tidak pernah ditanam di kode.", systemImage: "lock")
                        .font(.caption)
                        .foregroundStyle(MColor.n600)
                        .labelStyle(CompactLabelStyle())
                }
                .padding(MSpace.md)
                .glassEffect(.regular, in: .rect(cornerRadius: MRadius.lg))
            }
            .padding(.horizontal, MSpace.screen)
            .padding(.bottom, MSpace.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: MSpace.sm) {
                Button("Lanjut", action: saveAndContinue)
                    .buttonStyle(.primaryCapsule)
                    .disabled(speechKey.isEmpty && summaryKey.isEmpty)
                Button("Nanti saja", action: onNext)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MColor.n0)
            }
            .padding(.horizontal, MSpace.screen)
            .padding(.bottom, MSpace.xs)
        }
        .toolbar(.hidden, for: .navigationBar)
        .screenBackground(MBackground.deep)
    }

    private func keySection(_ kind: APIKeyKind, vendor: String?, key: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: MSpace.xs) {
            HStack {
                Text(kind.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MColor.n900)
                Spacer()
                // TODO(UI): jadikan menu pilihan vendor setelah PLAN-logic D4 (vendor LLM) diputuskan.
                Text(vendor ?? "Belum dipilih")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(vendor == nil ? MColor.n600 : MColor.brand700)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(vendor == nil ? MColor.n100 : MColor.brand50, in: .capsule)
            }
            KeyField(label: "API key \(kind.title)", key: key)
        }
    }

    private func saveAndContinue() {
        if !speechKey.isEmpty { try? APIKeyStore.save(speechKey, for: .speechToText) }
        if !summaryKey.isEmpty { try? APIKeyStore.save(summaryKey, for: .summary) }
        onNext()
    }
}

#Preview {
    NavigationStack {
        OnboardingKeyView {}
    }
}
