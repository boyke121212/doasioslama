import Foundation
import Security

final class SecurePrefs {

    private let service = "com.toelve.doas.secureprefs"

    init() {}

    private func save(key: String, value: String) {

        guard let data = value.data(using: .utf8) else { return }

        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func get(key: String) -> String? {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        return nil
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Public API

    func saveAccessToken(_ token: String) {
        save(key: "AccessToken", value: token)
    }

    func saveRefreshToken(_ token: String) {
        save(key: "RefreshToken", value: token)
    }

    func saveAesKey(_ key: String) {
        save(key: "AESKey", value: key)
    }

    func getAccessToken() -> String? {
        return get(key: "AccessToken")
    }

    func getRefreshToken() -> String? {
        return get(key: "RefreshToken")
    }

    func getAesKey() -> String? {
        return get(key: "AESKey")
    }

    func clear() {
        delete(key: "AccessToken")
        delete(key: "RefreshToken")
        delete(key: "AESKey")
    }
}
