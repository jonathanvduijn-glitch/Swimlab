import Foundation
import Security

// Bewaart de Claude API-sleutel versleuteld in de Keychain van dit toestel.
// De sleutel komt nooit in de code, in logs of in UserDefaults.
enum KeychainService {
    private static let service = "WineRack"
    private static let account = "claude-api-key"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    // Slaat de sleutel op (een oude sleutel wordt eerst verwijderd).
    @discardableResult
    static func saveAPIKey(_ key: String) -> Bool {
        deleteAPIKey()
        var query = baseQuery
        query[kSecValueData as String] = Data(key.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    // Leest de sleutel; nil als er nog geen is.
    static func loadAPIKey() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else { return nil }
        return key
    }

    @discardableResult
    static func deleteAPIKey() -> Bool {
        let status = SecItemDelete(baseQuery as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
