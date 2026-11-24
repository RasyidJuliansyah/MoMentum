import Foundation
import Security

/// Simpan/ambil API key dari iOS Keychain. Tidak pernah ditulis di kode atau UserDefaults.
enum KeychainStore {
    enum Key: String {
        case assemblyAIAPIKey
        case llmAPIKey
    }

    /// Error melempar bukan diam-diam gagal (L1.5).
    struct KeychainError: Error {
        let status: OSStatus
    }

    /// Namespace item Keychain, supaya tidak bentrok dengan app lain yang pakai account name sama.
    static let service = "com.momentum.apikeys"

    static func set(_ value: String, for key: Key) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        // Readable segera setelah unlock pertama, bertahan sampai proses berjalan di background
        // (mis. proses transkripsi lanjut saat layar terkunci); tidak disinkronkan ke device lain.
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    static func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

