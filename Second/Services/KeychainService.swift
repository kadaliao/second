import Foundation
import Security
import CryptoKit

/// Keychain service for vault key storage
class KeychainService {

    enum KeychainError: Error {
        case saveFailed(OSStatus)
        case loadFailed(OSStatus)
        case deleteFailed(OSStatus)
        case keyNotFound
    }

    func saveKey(_ key: SymmetricKey, identifier: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecAttrService as String: "com.second.totp",
            kSecValueData as String: keyData,
            kSecAttrSynchronizable as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func loadKey(identifier: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecAttrService as String: "com.second.totp",
            kSecReturnData as String: true,
            kSecAttrSynchronizable as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            throw status == errSecItemNotFound ? KeychainError.keyNotFound : KeychainError.loadFailed(status)
        }

        guard let keyData = item as? Data else {
            throw KeychainError.loadFailed(errSecInvalidData)
        }

        return SymmetricKey(data: keyData)
    }

    func deleteKey(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecAttrService as String: "com.second.totp"
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
