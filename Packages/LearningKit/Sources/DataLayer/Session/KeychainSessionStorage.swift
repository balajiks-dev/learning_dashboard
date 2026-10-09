import Foundation
import Security

/// Persists the auth token in the Keychain, never in UserDefaults or on disk.
/// `AfterFirstUnlockThisDeviceOnly` keeps it out of backups and off other
/// devices, while still letting background refreshes read it.
public struct KeychainSessionStorage: SessionStorage {
    public enum KeychainError: Error, Equatable {
        case unhandled(OSStatus)
    }

    private let service: String
    private let account = "auth.session"

    public init(service: String) {
        self.service = service
    }

    public func load() -> StoredSession? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    public func save(_ session: StoredSession) throws {
        let data = try JSONEncoder().encode(session)
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandled(status) }
    }

    public func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
