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

    // Slaat de sleutel op. Een bestaande sleutel wordt overschreven, niet eerst gewist,
    // zodat de oude sleutel blijft staan als het bewaren mislukt.
    @discardableResult
    static func saveAPIKey(_ key: String) -> Bool {
        let data = Data(key.utf8)
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return true }
        guard status == errSecItemNotFound else { return false }

        var query = baseQuery
        query[kSecValueData as String] = data
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
