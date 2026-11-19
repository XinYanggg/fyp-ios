//
//  KeychainStore.swift
//  durian.health
//

import Foundation
import Security

/// Minimal Keychain wrapper for small string secrets such as the auth token.
nonisolated struct KeychainStore {
    enum KeychainError: LocalizedError {
        case unhandled(OSStatus)

        var errorDescription: String? {
            switch self {
            case .unhandled(let status):
                return "Keychain error (\(status))."
            }
        }
    }

    var service: String = Bundle.main.bundleIdentifier ?? "com.farnxinyang.durian-health"

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }

    func read(_ key: String) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func save(_ value: String, for key: String) throws {
        let data = Data(value.utf8)
        let status = SecItemUpdate(
            baseQuery(for: key) as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else { throw KeychainError.unhandled(status) }

        var add = baseQuery(for: key)
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw KeychainError.unhandled(addStatus) }
    }

    func delete(_ key: String) {
        SecItemDelete(baseQuery(for: key) as CFDictionary)
    }
}
