//
//  KeychainService.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation
import Security
import CryptoKit

/// Keychain service for secure vault key storage with iCloud Keychain sync
///
/// Manages the 256-bit AES encryption key used to protect vault data.
/// Keys are stored in iCloud Keychain for automatic sync across user's devices.
///
/// - Important: The vault key must remain secure. It is stored in Keychain with `kSecAttrSynchronizable` enabled.
class KeychainService {
    
    private static let service = "com.second.totp"
    private static let account = "vaultKey"

    enum KeychainError: Error, LocalizedError {
        case unableToSave
        case unableToLoad
        case keyNotFound
        case unableToDelete

        var errorDescription: String? {
            switch self {
            case .unableToSave:
                return "无法保存密钥到钥匙串"
            case .unableToLoad:
                return "无法从钥匙串加载密钥"
            case .keyNotFound:
                return "钥匙串中未找到密钥"
            case .unableToDelete:
                return "无法从钥匙串删除密钥"
            }
        }
    }

    /// Generate a new 256-bit AES vault encryption key
    ///
    /// - Returns: A cryptographically secure random 256-bit symmetric key
    ///
    /// - Note: This key should be saved to Keychain immediately using `saveVaultKey(_:)`
    static func generateVaultKey() -> SymmetricKey {
        Logger.info("生成新的 256 位保险库密钥")
        return SymmetricKey(size: .bits256)
    }

    /// Save vault encryption key to iCloud Keychain
    ///
    /// - Parameter key: The 256-bit symmetric key to save
    /// - Throws: `KeychainError.unableToSave` if the save operation fails
    ///
    /// - Important: The key is saved with `kSecAttrSynchronizable` enabled for iCloud sync
    static func saveVaultKey(_ key: SymmetricKey) throws {
        Logger.info("开始保存保险库密钥到钥匙串")
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecValueData as String: keyData,
            kSecAttrSynchronizable as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Try to delete existing key first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            Logger.error("保存密钥到钥匙串失败 (状态码: \(status))")
            throw KeychainError.unableToSave
        }

        Logger.info("保险库密钥已成功保存到钥匙串 (启用 iCloud 同步)")
    }

    /// Load vault encryption key from iCloud Keychain
    ///
    /// - Returns: The stored 256-bit symmetric encryption key
    /// - Throws:
    ///   - `KeychainError.keyNotFound` if no key exists in Keychain
    ///   - `KeychainError.unableToLoad` if the load operation fails
    ///
    /// - Note: Queries iCloud Keychain with `kSecAttrSynchronizable` enabled
    static func loadVaultKey() throws -> SymmetricKey {
        Logger.info("开始从钥匙串加载保险库密钥")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecAttrSynchronizable as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                Logger.warning("钥匙串中未找到密钥")
                throw KeychainError.keyNotFound
            } else {
                Logger.error("从钥匙串加载密钥失败 (状态码: \(status))")
                throw KeychainError.unableToLoad
            }
        }

        guard let keyData = item as? Data else {
            Logger.error("钥匙串返回的数据格式无效")
            throw KeychainError.unableToLoad
        }

        Logger.info("保险库密钥已成功从钥匙串加载")
        return SymmetricKey(data: keyData)
    }

    /// Check if vault encryption key exists in Keychain
    ///
    /// - Returns: `true` if a key exists, `false` otherwise
    ///
    /// - Note: This is a non-throwing convenience method for checking key existence
    static func vaultKeyExists() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnData as String: false,
            kSecAttrSynchronizable as String: true
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        let exists = status == errSecSuccess
        Logger.debug("钥匙串密钥存在性检查: \(exists ? "存在" : "不存在")")
        return exists
    }

    /// Delete vault encryption key from Keychain
    ///
    /// - Throws: `KeychainError.unableToDelete` if the deletion fails
    ///
    /// - Warning: This permanently removes the vault key. Without this key, encrypted vault data cannot be decrypted.
    static func deleteVaultKey() throws {
        Logger.warning("正在从钥匙串删除保险库密钥")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecAttrSynchronizable as String: true
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            Logger.error("从钥匙串删除密钥失败 (状态码: \(status))")
            throw KeychainError.unableToDelete
        }

        Logger.info("保险库密钥已从钥匙串删除")
    }
}
