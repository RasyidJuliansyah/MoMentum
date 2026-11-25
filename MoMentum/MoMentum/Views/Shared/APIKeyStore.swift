import Foundation

/// Satu-satunya tempat UI menyentuh `KeychainStore` (milik sesi Logic). Kalau signature `KeychainStore`
/// berubah (PLAN-logic.md L1.5), cukup file ini yang disesuaikan.
enum APIKeyKind: CaseIterable, Identifiable {
    case speechToText
    case summary

    var id: Self { self }

    var title: String {
        switch self {
        case .speechToText: "Speech-to-text"
        case .summary: "Ringkasan (LLM)"
        }
    }

    /// Nama penyedia. Ringkasan memilih vendor dari key (`AutoSummaryProvider`): `sk-ant-` ke Claude.
    var providerName: String {
        switch self {
        case .speechToText: "AssemblyAI · diarization"
        case .summary:
            AutoSummaryProvider.isAnthropicKey(APIKeyStore.key(for: .summary))
                ? "Anthropic · Claude Opus 5.5"
                : "Anthropic (sk-ant-…) atau OpenAI"
        }
    }

    var systemImage: String {
        switch self {
        case .speechToText: "waveform"
        case .summary: "sparkles"
        }
    }

    fileprivate var keychainKey: KeychainStore.Key {
        switch self {
        case .speechToText: .assemblyAIAPIKey
        case .summary: .llmAPIKey
        }
    }
}

enum APIKeyStore {
    static func key(for kind: APIKeyKind) -> String? {
        KeychainStore.get(kind.keychainKey)
    }

    static func save(_ value: String, for kind: APIKeyKind) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try KeychainStore.set(trimmed, for: kind.keychainKey)
    }

    static func delete(_ kind: APIKeyKind) {
        KeychainStore.delete(kind.keychainKey)
    }
}

enum KeyMask {
    /// "••••••••••••3f9a", atau "sk-ant-••••••••7c21" untuk key berawalan "sk-".
    static func masked(_ key: String) -> String {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 8 else { return String(repeating: "•", count: trimmed.count) }
        let suffix = String(trimmed.suffix(4))
        if trimmed.hasPrefix("sk-") {
            return String(trimmed.prefix(7)) + String(repeating: "•", count: 8) + suffix
        }
        return String(repeating: "•", count: 12) + suffix
    }
}
