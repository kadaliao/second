//
//  EncryptionService.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation
import CryptoKit

/// AES-GCM authenticated encryption service for vault data
///
/// Provides secure encryption and decryption of vault data using AES-256-GCM.
/// Includes authentication to detect tampering and ensures data integrity.
///
/// - Note: Performance optimized with pre-configured JSON encoder/decoder (<200ms for typical vault)
class EncryptionService {

    // Pre-configured encoder and decoder for better performance
    private static let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()

    private static let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    enum EncryptionError: Error, LocalizedError {
        case encryptionFailed
        case decryptionFailed
        case authenticationFailed

        var errorDescription: String? {
            switch self {
            case .encryptionFailed:
                return "加密失败"
            case .decryptionFailed:
                return "解密失败"
            case .authenticationFailed:
                return "数据完整性验证失败"
            }
        }
    }

    /// Encrypt vault data using AES-256-GCM authenticated encryption
    ///
    /// - Parameters:
    ///   - vault: The vault containing tokens to encrypt
    ///   - key: The 256-bit symmetric encryption key
    /// - Returns: Encrypted data including nonce and authentication tag
    /// - Throws: `EncryptionError.encryptionFailed` if encryption fails
    ///
    /// - Note: The returned data contains nonce + ciphertext + tag in combined format
    static func encrypt(vault: Vault, using key: SymmetricKey) throws -> Data {
        Logger.info("开始加密保险库 (令牌数: \(vault.tokens.count))")

        let jsonData = try encoder.encode(vault)
        Logger.debug("保险库已序列化为 JSON (大小: \(jsonData.count) 字节)")

        let sealedBox = try AES.GCM.seal(jsonData, using: key)

        guard let combined = sealedBox.combined else {
            Logger.error("加密失败:无法获取组合数据")
            throw EncryptionError.encryptionFailed
        }

        Logger.info("保险库加密成功 (密文大小: \(combined.count) 字节)")
        return combined
    }

    /// Decrypt vault data using AES-256-GCM authenticated decryption
    ///
    /// - Parameters:
    ///   - encryptedData: The encrypted data in combined format (nonce + ciphertext + tag)
    ///   - key: The 256-bit symmetric encryption key used for encryption
    /// - Returns: Decrypted vault object
    /// - Throws:
    ///   - `EncryptionError.authenticationFailed` if the authentication tag is invalid (wrong key or tampered data)
    ///   - `EncryptionError.decryptionFailed` if decryption fails for other reasons
    ///
    /// - Important: This method verifies data integrity. Any tampering will cause authentication failure.
    static func decrypt(encryptedData: Data, using key: SymmetricKey) throws -> Vault {
        Logger.info("开始解密保险库 (密文大小: \(encryptedData.count) 字节)")

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)

            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            Logger.debug("数据解密成功 (明文大小: \(decryptedData.count) 字节)")

            let vault = try decoder.decode(Vault.self, from: decryptedData)
            Logger.info("保险库解密成功 (令牌数: \(vault.tokens.count))")

            return vault
        } catch is CryptoKitError {
            Logger.error("解密失败 - 认证失败:密钥错误或数据已被篡改")
            throw EncryptionError.authenticationFailed
        } catch {
            Logger.error("解密失败: \(error.localizedDescription)")
            throw EncryptionError.decryptionFailed
        }
    }
}
