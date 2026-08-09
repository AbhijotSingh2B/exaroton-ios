import Security
import Foundation

// MARK: - Keychain Manager
// Provides secure storage for API tokens.
// Using a service-key pattern so future multi-account storage can simply
// iterate over all keys with the "exaroton." prefix.

enum KeychainError: Error {
    case unhandledError(status: OSStatus)
    case unexpectedData
    case notFound
}

struct KeychainManager {

    static let activeTokenKey = "exaroton.active.token"
    static let activeAccountNameKey = "exaroton.active.name"

    // MARK: Save

    static func save(token: String, forKey key: String = activeTokenKey) throws {
        guard let data = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      "com.exaroton.ios",
            kSecAttrAccount as String:      key,
            kSecValueData as String:        data
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: Load

    static func load(forKey key: String = activeTokenKey) throws -> String {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      "com.exaroton.ios",
            kSecAttrAccount as String:      key,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else { throw KeychainError.notFound }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }

        guard let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return string
    }

    // MARK: Delete

    static func delete(forKey key: String = activeTokenKey) {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  "com.exaroton.ios",
            kSecAttrAccount as String:  key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
