//
//  VaultIntegrationTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
import CryptoKit
@testable import Second

final class VaultIntegrationTests: XCTestCase {

    var syncService: iCloudSyncService!

    override func setUp() {
        super.setUp()
        syncService = iCloudSyncService()
        // Clean up before tests
        syncService.deleteEncryptedVault()
        try? KeychainService.deleteVaultKey()
    }

    override func tearDown() {
        // Clean up after tests
        syncService.deleteEncryptedVault()
        try? KeychainService.deleteVaultKey()
        syncService = nil
        super.tearDown()
    }

    // MARK: - End-to-End Vault Workflow Tests

    func testEndToEnd_CreateEncryptSaveLoadDecrypt_SingleToken() throws {
        // 1. Create vault with one token
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP")
        ])

        // 2. Generate and save encryption key
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)

        // 3. Encrypt vault
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)

        // 4. Save to iCloud
        try syncService.saveEncryptedVault(encryptedData)

        // 5. Load from iCloud
        let loadedData = try syncService.loadEncryptedVault()

        // 6. Load key from Keychain
        let loadedKey = try KeychainService.loadVaultKey()

        // 7. Decrypt vault
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: loadedKey)

        // 8. Verify data integrity
        XCTAssertEqual(decryptedVault.tokens.count, 1)
        XCTAssertEqual(decryptedVault.tokens[0].issuer, "GitHub")
        XCTAssertEqual(decryptedVault.tokens[0].account, "user@github.com")
        XCTAssertEqual(decryptedVault.tokens[0].secret, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(decryptedVault.tokens[0].digits, 6)
        XCTAssertEqual(decryptedVault.tokens[0].period, 30)
        XCTAssertEqual(decryptedVault.tokens[0].algorithm, .sha1)
    }

    func testEndToEnd_CreateEncryptSaveLoadDecrypt_MultipleTokens() throws {
        // 1. Create vault with multiple tokens
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "GEZDGNBVGY3TQOJQ", digits: 8, period: 60, algorithm: .sha256),
            Token(issuer: "Microsoft", account: "user@outlook.com", secret: "MFRGGZDFMZTWQ2LK")
        ])

        // 2. Generate and save encryption key
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)

        // 3. Encrypt vault
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)

        // 4. Save to iCloud
        try syncService.saveEncryptedVault(encryptedData)

        // 5. Load from iCloud
        let loadedData = try syncService.loadEncryptedVault()

        // 6. Load key from Keychain
        let loadedKey = try KeychainService.loadVaultKey()

        // 7. Decrypt vault
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: loadedKey)

        // 8. Verify all tokens
        XCTAssertEqual(decryptedVault.tokens.count, 3)

        XCTAssertEqual(decryptedVault.tokens[0].issuer, "GitHub")
        XCTAssertEqual(decryptedVault.tokens[0].digits, 6)
        XCTAssertEqual(decryptedVault.tokens[0].period, 30)
        XCTAssertEqual(decryptedVault.tokens[0].algorithm, .sha1)

        XCTAssertEqual(decryptedVault.tokens[1].issuer, "Google")
        XCTAssertEqual(decryptedVault.tokens[1].digits, 8)
        XCTAssertEqual(decryptedVault.tokens[1].period, 60)
        XCTAssertEqual(decryptedVault.tokens[1].algorithm, .sha256)

        XCTAssertEqual(decryptedVault.tokens[2].issuer, "Microsoft")
    }

    func testEndToEnd_EmptyVault_Works() throws {
        // 1. Create empty vault
        let vault = Vault(tokens: [])

        // 2. Generate and save encryption key
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)

        // 3. Encrypt vault
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)

        // 4. Save to iCloud
        try syncService.saveEncryptedVault(encryptedData)

        // 5. Load from iCloud
        let loadedData = try syncService.loadEncryptedVault()

        // 6. Load key from Keychain
        let loadedKey = try KeychainService.loadVaultKey()

        // 7. Decrypt vault
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: loadedKey)

        // 8. Verify empty
        XCTAssertEqual(decryptedVault.tokens.count, 0)
    }

    // MARK: - Update Workflow Tests

    func testEndToEnd_AddToken_SaveLoadDecrypt() throws {
        // 1. Start with one token
        var vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP")
        ])

        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)

        var encryptedData = try EncryptionService.encrypt(vault: vault, using: key)
        try syncService.saveEncryptedVault(encryptedData)

        // 2. Add second token
        vault.tokens.append(Token(issuer: "Google", account: "user@gmail.com", secret: "GEZDGNBVGY3TQOJQ"))

        // 3. Encrypt and save updated vault
        encryptedData = try EncryptionService.encrypt(vault: vault, using: key)
        try syncService.saveEncryptedVault(encryptedData)

        // 4. Load and decrypt
        let loadedData = try syncService.loadEncryptedVault()
        let loadedKey = try KeychainService.loadVaultKey()
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: loadedKey)

        // 5. Verify both tokens exist
        XCTAssertEqual(decryptedVault.tokens.count, 2)
        XCTAssertEqual(decryptedVault.tokens[0].issuer, "GitHub")
        XCTAssertEqual(decryptedVault.tokens[1].issuer, "Google")
    }

    func testEndToEnd_RemoveToken_SaveLoadDecrypt() throws {
        // 1. Start with multiple tokens
        var vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "GEZDGNBVGY3TQOJQ"),
            Token(issuer: "Microsoft", account: "user@outlook.com", secret: "MFRGGZDFMZTWQ2LK")
        ])

        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)

        var encryptedData = try EncryptionService.encrypt(vault: vault, using: key)
        try syncService.saveEncryptedVault(encryptedData)

        // 2. Remove middle token
        vault.tokens.remove(at: 1)

        // 3. Encrypt and save updated vault
        encryptedData = try EncryptionService.encrypt(vault: vault, using: key)
        try syncService.saveEncryptedVault(encryptedData)

        // 4. Load and decrypt
        let loadedData = try syncService.loadEncryptedVault()
        let loadedKey = try KeychainService.loadVaultKey()
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: loadedKey)

        // 5. Verify Google token was removed
        XCTAssertEqual(decryptedVault.tokens.count, 2)
        XCTAssertEqual(decryptedVault.tokens[0].issuer, "GitHub")
        XCTAssertEqual(decryptedVault.tokens[1].issuer, "Microsoft")
        XCTAssertFalse(decryptedVault.tokens.contains(where: { $0.issuer == "Google" }))
    }

    // MARK: - TOTP Generation Integration Tests

    func testEndToEnd_SaveLoadGenerateTOTP() throws {
        // 1. Create vault with token
        let vault = Vault(tokens: [
            Token(issuer: "Test", account: "test@test.com", secret: "JBSWY3DPEHPK3PXP")
        ])

        // 2. Save to iCloud
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)
        try syncService.saveEncryptedVault(encryptedData)

        // 3. Load from iCloud
        let loadedData = try syncService.loadEncryptedVault()
        let loadedKey = try KeychainService.loadVaultKey()
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: loadedKey)

        // 4. Generate TOTP code
        let token = decryptedVault.tokens[0]
        let code = TOTPGenerator.generate(token: token, time: Date())

        // 5. Verify code format
        XCTAssertEqual(code.count, 6, "Should generate 6-digit code")
        XCTAssertTrue(code.allSatisfy { $0.isNumber }, "Code should contain only digits")
    }

    // MARK: - QR Code Integration Tests

    func testEndToEnd_ParseQRAddToVaultSaveLoad() throws {
        // 1. Parse QR code URI
        let uri = "otpauth://totp/GitHub:user@github.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
        let token = try QRCodeParser.parse(uri)

        // 2. Create vault with parsed token
        let vault = Vault(tokens: [token])

        // 3. Encrypt and save
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)
        try syncService.saveEncryptedVault(encryptedData)

        // 4. Load and decrypt
        let loadedData = try syncService.loadEncryptedVault()
        let loadedKey = try KeychainService.loadVaultKey()
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: loadedKey)

        // 5. Verify token
        XCTAssertEqual(decryptedVault.tokens.count, 1)
        XCTAssertEqual(decryptedVault.tokens[0].issuer, "GitHub")
        XCTAssertEqual(decryptedVault.tokens[0].account, "user@github.com")
        XCTAssertEqual(decryptedVault.tokens[0].secret, "JBSWY3DPEHPK3PXP")
    }

    // MARK: - Error Recovery Tests

    func testEndToEnd_WrongKeyFailsDecryption() throws {
        // 1. Create and save vault with key1
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP")
        ])

        let key1 = KeychainService.generateVaultKey()
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key1)
        try syncService.saveEncryptedVault(encryptedData)

        // 2. Try to decrypt with different key2
        let key2 = KeychainService.generateVaultKey()
        let loadedData = try syncService.loadEncryptedVault()

        // 3. Should fail to decrypt
        XCTAssertThrowsError(try EncryptionService.decrypt(encryptedData: loadedData, using: key2))
    }

    func testEndToEnd_CorruptediCloudDataFailsDecryption() throws {
        // 1. Save corrupted data to iCloud
        let corruptedData = Data([0x00, 0x01, 0x02, 0x03])
        try syncService.saveEncryptedVault(corruptedData)

        // 2. Try to decrypt
        let key = KeychainService.generateVaultKey()
        let loadedData = try syncService.loadEncryptedVault()

        // 3. Should fail to decrypt
        XCTAssertThrowsError(try EncryptionService.decrypt(encryptedData: loadedData, using: key))
    }

    // MARK: - Special Characters Integration Tests

    func testEndToEnd_UnicodeTokens_PreservesData() throws {
        // 1. Create vault with Unicode characters
        let vault = Vault(tokens: [
            Token(issuer: "测试公司", account: "用户@例子.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Test 🔐", account: "user@test.com 🚀", secret: "GEZDGNBVGY3TQOJQ")
        ])

        // 2. Save to iCloud
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)
        try syncService.saveEncryptedVault(encryptedData)

        // 3. Load and decrypt
        let loadedData = try syncService.loadEncryptedVault()
        let loadedKey = try KeychainService.loadVaultKey()
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: loadedKey)

        // 4. Verify Unicode preservation
        XCTAssertEqual(decryptedVault.tokens[0].issuer, "测试公司")
        XCTAssertEqual(decryptedVault.tokens[0].account, "用户@例子.com")
        XCTAssertEqual(decryptedVault.tokens[1].issuer, "Test 🔐")
        XCTAssertEqual(decryptedVault.tokens[1].account, "user@test.com 🚀")
    }

    // MARK: - Large Vault Tests

    func testEndToEnd_50Tokens_SaveLoadWorks() throws {
        // 1. Create vault with 50 tokens
        let tokens = (0..<50).map { index in
            Token(
                issuer: "Service\(index)",
                account: "user\(index)@example.com",
                secret: "JBSWY3DPEHPK3PXP",
                digits: 6,
                period: 30,
                algorithm: .sha1
            )
        }
        let vault = Vault(tokens: tokens)

        // 2. Save to iCloud
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)
        try syncService.saveEncryptedVault(encryptedData)

        // 3. Load and decrypt
        let loadedData = try syncService.loadEncryptedVault()
        let loadedKey = try KeychainService.loadVaultKey()
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: loadedKey)

        // 4. Verify all 50 tokens
        XCTAssertEqual(decryptedVault.tokens.count, 50)
        for (index, token) in decryptedVault.tokens.enumerated() {
            XCTAssertEqual(token.issuer, "Service\(index)")
            XCTAssertEqual(token.account, "user\(index)@example.com")
        }
    }

    // MARK: - Performance Tests

    func testPerformance_EndToEndWorkflow_50Tokens() throws {
        let tokens = (0..<50).map { index in
            Token(
                issuer: "Service\(index)",
                account: "user\(index)@example.com",
                secret: "JBSWY3DPEHPK3PXP"
            )
        }
        let vault = Vault(tokens: tokens)
        let key = KeychainService.generateVaultKey()

        measure {
            do {
                // Encrypt
                let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)

                // Save to iCloud
                try syncService.saveEncryptedVault(encryptedData)

                // Load from iCloud
                let loadedData = try syncService.loadEncryptedVault()

                // Decrypt
                _ = try EncryptionService.decrypt(encryptedData: loadedData, using: key)
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
}
