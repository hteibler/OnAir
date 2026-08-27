import Foundation
import Security

/// Minimal generic-password wrapper for the modern (data-protection) Keychain.
///
/// The data-protection keychain never shows the legacy "app wants to use the
/// keychain" prompt, so calls are safe on any thread and never block. Writing
/// requires a real code signature (`application-identifier`); ad-hoc dev builds
/// get `errSecMissingEntitlement` on `set`, which callers handle by falling back
/// to `UserDefaults`.
enum KeychainStore {
    private static let service = "at.teibler.OnAir"

    private static func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }

    static func get(_ account: String) -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Returns `true` if the value was stored in the Keychain.
    @discardableResult
    static func set(_ value: String, for account: String) -> Bool {
        let query = baseQuery(account)
        let data = Data(value.utf8)
        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            return SecItemUpdate(query as CFDictionary,
                                 [kSecValueData as String: data] as CFDictionary) == errSecSuccess
        }
        var add = query
        add[kSecValueData as String] = data
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func delete(_ account: String) {
        SecItemDelete(baseQuery(account) as CFDictionary)
    }
}
