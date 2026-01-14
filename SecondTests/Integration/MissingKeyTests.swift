//
//  MissingKeyTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-17.
//

import XCTest
import CryptoKit
@testable import Second

final class MissingKeyTests: XCTestCase {

    var iCloudService: iCloudSyncService!
    var testVault: Vault!

    override func setUp() {
        super.setUp()
        iCloudService = iCloudSyncService()
        testVault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])

        // Clean up any existing test data
        cleanup()
    }

    override func tearDown() {
        cleanup()
        iCloudService = nil
        testVault = nil
        super.tearDown()
    }

    private func cleanup() {
        // Delete any existing vault key
        try? KeychainService.deleteVaultKey()
        // Delete any existing encrypted vault
        iCloudService.deleteEncryptedVault()
    }

    // MARK: - Missing Key Scenario Tests

    func testMissingKey_VaultExistsButNoKey_ThrowsKeyNotFoundError() throws {
        // Step 1: Create and save a vault with encryption (simulating Device A)
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)

        let encryptedData = try EncryptionService.encrypt(vault: testVault, using: key)
        try iCloudService.saveEncryptedVault(encryptedData)

        // Step 2: Delete the key from Keychain (simulating key missing scenario)
        try KeychainService.deleteVaultKey()

        // Step 3: Verify encrypted vault exists in iCloud
        XCTAssertTrue(iCloudService.encryptedVaultExists(), "Encrypted vault should exist in iCloud")

        // Step 4: Try to load key - should throw keyNotFound error
        XCTAssertThrowsError(try KeychainService.loadVaultKey()) { error in
            if let keychainError = error as? KeychainService.KeychainError {
                XCTAssertEqual(keychainError, KeychainService.KeychainError.keyNotFound,
                             "Should throw keyNotFound error")
            } else {
                XCTFail("Expected KeychainError.keyNotFound, got \(error)")
            }
        }
    }

    func testMissingKey_CannotDecryptVaultWithoutKey() throws {
        // Step 1: Create and save encrypted vault
        let originalKey = KeychainService.generateVaultKey()
        let encryptedData = try EncryptionService.encrypt(vault: testVault, using: originalKey)
        try iCloudService.saveEncryptedVault(encryptedData)

        // Step 2: Try to decrypt with a different key (simulating wrong/missing key)
        let wrongKey = KeychainService.generateVaultKey()

        let loadedData = try iCloudService.loadEncryptedVault()

        // Should throw decryption error
        XCTAssertThrowsError(try EncryptionService.decrypt(encryptedData: loadedData, using: wrongKey)) { error in
            // Should be CryptoKit authentication failure or decryption error
            XCTAssertTrue(error is CryptoKitError || error is EncryptionService.EncryptionError,
                         "Should throw encryption/decryption error")
        }
    }

    func testMissingKey_VaultKeyExistsCheck_ReturnsFalseWhenMissing() {
        // Initially no key should exist
        XCTAssertFalse(KeychainService.vaultKeyExists(), "Key should not exist initially")

        // Save a key
        let key = KeychainService.generateVaultKey()
        try? KeychainService.saveVaultKey(key)

        // Key should now exist
        XCTAssertTrue(KeychainService.vaultKeyExists(), "Key should exist after saving")

        // Delete the key
        try? KeychainService.deleteVaultKey()

        // Key should no longer exist
        XCTAssertFalse(KeychainService.vaultKeyExists(), "Key should not exist after deletion")
    }

    func testMissingKey_ErrorStateDetection_EncryptedVaultExistsButNoKey() throws {
        // This test simulates the exact scenario that should trigger error state in UI:
        // 1. Encrypted vault exists in iCloud (synced from another device)
        // 2. But vault key is not in Keychain (iCloud Keychain not enabled or not synced yet)

        // Step 1: Save encrypted vault to iCloud (simulating sync from Device A)
        let key = KeychainService.generateVaultKey()
        let encryptedData = try EncryptionService.encrypt(vault: testVault, using: key)
        try iCloudService.saveEncryptedVault(encryptedData)

        // Step 2: Ensure key is not in Keychain (simulating Device B without key)
        try? KeychainService.deleteVaultKey()

        // Step 3: Check conditions for error state
        let vaultExists = iCloudService.encryptedVaultExists()
        let keyExists = KeychainService.vaultKeyExists()

        // Verify error state condition
        XCTAssertTrue(vaultExists, "Encrypted vault should exist")
        XCTAssertFalse(keyExists, "Vault key should not exist")
        XCTAssertTrue(vaultExists && !keyExists, "Error state condition: vault exists but key missing")
    }

    // MARK: - Recovery Scenario Tests

    func testRecovery_KeyAppearsAfterSync_CanDecryptVault() throws {
        // This test simulates the recovery scenario:
        // 1. Device B has encrypted vault but no key initially
        // 2. iCloud Keychain syncs and key appears
        // 3. Device B can now decrypt the vault

        // Step 1: Create and encrypt vault
        let key = KeychainService.generateVaultKey()
        let encryptedData = try EncryptionService.encrypt(vault: testVault, using: key)
        try iCloudService.saveEncryptedVault(encryptedData)

        // Step 2: Delete key (simulating missing key state)
        try KeychainService.deleteVaultKey()
        XCTAssertFalse(KeychainService.vaultKeyExists())

        // Step 3: Re-save key (simulating iCloud Keychain sync)
        try KeychainService.saveVaultKey(key)
        XCTAssertTrue(KeychainService.vaultKeyExists())

        // Step 4: Load and decrypt vault successfully
        let loadedKey = try KeychainService.loadVaultKey()
        let loadedEncryptedData = try iCloudService.loadEncryptedVault()
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedEncryptedData, using: loadedKey)

        // Verify vault data
        XCTAssertEqual(decryptedVault.tokens.count, 1)
        XCTAssertEqual(decryptedVault.tokens[0].issuer, "GitHub")
        XCTAssertEqual(decryptedVault.tokens[0].account, "user@example.com")
    }

    func testRecovery_FirstLaunchOnNewDevice_CreatesNewKeyAndVault() throws {
        // This test simulates a fresh install on a new device:
        // 1. No vault key in Keychain
        // 2. No encrypted vault in iCloud
        // 3. App should create new key and empty vault

        // Step 1: Ensure clean state
        XCTAssertFalse(KeychainService.vaultKeyExists())
        XCTAssertFalse(iCloudService.encryptedVaultExists())

        // Step 2: Generate and save new key
        let newKey = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(newKey)

        // Step 3: Create and save empty vault
        let emptyVault = Vault(tokens: [])
        let encryptedData = try EncryptionService.encrypt(vault: emptyVault, using: newKey)
        try iCloudService.saveEncryptedVault(encryptedData)

        // Step 4: Verify setup
        XCTAssertTrue(KeychainService.vaultKeyExists())
        XCTAssertTrue(iCloudService.encryptedVaultExists())

        // Step 5: Load and verify empty vault
        let loadedKey = try KeychainService.loadVaultKey()
        let loadedEncryptedData = try iCloudService.loadEncryptedVault()
        let loadedVault = try EncryptionService.decrypt(encryptedData: loadedEncryptedData, using: loadedKey)

        XCTAssertEqual(loadedVault.tokens.count, 0, "New vault should be empty")
    }

    // MARK: - Error Message Tests

    func testMissingKey_ErrorDescription_IsLocalized() {
        let error = KeychainService.KeychainError.keyNotFound

        let description = error.errorDescription
        XCTAssertNotNil(description, "Error should have a description")
        XCTAssertEqual(description, "钥匙串中未找到密钥", "Error description should be in Chinese")
    }
}
