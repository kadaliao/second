//
//  KeychainServiceTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
import CryptoKit
@testable import Second

final class KeychainServiceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clean up any existing test key
        try? KeychainService.deleteVaultKey()
    }
    
    override func tearDown() {
        // Clean up after tests
        try? KeychainService.deleteVaultKey()
        super.tearDown()
    }
    
    // MARK: - Key Generation Tests
    
    func testGenerateVaultKey_Creates256BitKey() {
        let key = KeychainService.generateVaultKey()
        
        let keyData = key.withUnsafeBytes { Data($0) }
        XCTAssertEqual(keyData.count, 32, "256-bit key should be 32 bytes")
    }
    
    func testGenerateVaultKey_GeneratesUniqueKeys() {
        let key1 = KeychainService.generateVaultKey()
        let key2 = KeychainService.generateVaultKey()
        
        let keyData1 = key1.withUnsafeBytes { Data($0) }
        let keyData2 = key2.withUnsafeBytes { Data($0) }
        
        XCTAssertNotEqual(keyData1, keyData2, "Each generated key should be unique")
    }
    
    // MARK: - Save Key Tests
    
    func testSaveVaultKey_SuccessfullySaves() {
        let key = KeychainService.generateVaultKey()
        
        XCTAssertNoThrow(try KeychainService.saveVaultKey(key))
    }
    
    func testSaveVaultKey_OverwritesExistingKey() {
        let key1 = KeychainService.generateVaultKey()
        let key2 = KeychainService.generateVaultKey()
        
        XCTAssertNoThrow(try KeychainService.saveVaultKey(key1))
        XCTAssertNoThrow(try KeychainService.saveVaultKey(key2))
        
        // Should be able to save twice without error
    }
    
    // MARK: - Load Key Tests
    
    func testLoadVaultKey_NoKeySaved_ThrowsError() {
        XCTAssertThrowsError(try KeychainService.loadVaultKey()) { error in
            guard case KeychainService.KeychainError.keyNotFound = error else {
                XCTFail("Expected keyNotFound error")
                return
            }
        }
    }
    
    func testLoadVaultKey_AfterSave_ReturnsCorrectKey() throws {
        let originalKey = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(originalKey)
        
        let loadedKey = try KeychainService.loadVaultKey()
        
        let originalData = originalKey.withUnsafeBytes { Data($0) }
        let loadedData = loadedKey.withUnsafeBytes { Data($0) }
        
        XCTAssertEqual(originalData, loadedData, "Loaded key should match saved key")
    }
    
    // MARK: - Key Exists Tests
    
    func testVaultKeyExists_NoKey_ReturnsFalse() {
        XCTAssertFalse(KeychainService.vaultKeyExists())
    }
    
    func testVaultKeyExists_AfterSave_ReturnsTrue() throws {
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)
        
        XCTAssertTrue(KeychainService.vaultKeyExists())
    }
    
    func testVaultKeyExists_AfterDelete_ReturnsFalse() throws {
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)
        
        try KeychainService.deleteVaultKey()
        
        XCTAssertFalse(KeychainService.vaultKeyExists())
    }
    
    // MARK: - Delete Key Tests
    
    func testDeleteVaultKey_KeyExists_DeletesSuccessfully() throws {
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)
        
        XCTAssertNoThrow(try KeychainService.deleteVaultKey())
        XCTAssertFalse(KeychainService.vaultKeyExists())
    }
    
    func testDeleteVaultKey_NoKey_DoesNotThrow() {
        // Should not throw even if no key exists
        XCTAssertNoThrow(try KeychainService.deleteVaultKey())
    }
    
    // MARK: - Round Trip Tests
    
    func testRoundTrip_SaveAndLoad_PreservesKeyData() throws {
        let originalKey = KeychainService.generateVaultKey()
        
        // Save
        try KeychainService.saveVaultKey(originalKey)
        
        // Verify exists
        XCTAssertTrue(KeychainService.vaultKeyExists())
        
        // Load
        let loadedKey = try KeychainService.loadVaultKey()
        
        // Compare
        let originalData = originalKey.withUnsafeBytes { Data($0) }
        let loadedData = loadedKey.withUnsafeBytes { Data($0) }
        XCTAssertEqual(originalData, loadedData)
    }
    
    func testRoundTrip_SaveDeleteSaveAgain_Works() throws {
        let key1 = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key1)
        
        try KeychainService.deleteVaultKey()
        
        let key2 = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key2)
        
        let loadedKey = try KeychainService.loadVaultKey()
        
        let key2Data = key2.withUnsafeBytes { Data($0) }
        let loadedData = loadedKey.withUnsafeBytes { Data($0) }
        XCTAssertEqual(key2Data, loadedData)
    }
    
    // MARK: - Integration with Encryption Tests
    
    func testIntegration_KeyUsedForEncryption_Works() throws {
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)
        
        let vault = Vault(tokens: [
            Token(issuer: "Test", account: "test@test.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        // Encrypt with saved key
        let loadedKey = try KeychainService.loadVaultKey()
        let encrypted = try EncryptionService.encrypt(vault: vault, using: loadedKey)
        
        // Decrypt with loaded key
        let decrypted = try EncryptionService.decrypt(encryptedData: encrypted, using: loadedKey)
        
        XCTAssertEqual(decrypted.tokens.count, 1)
        XCTAssertEqual(decrypted.tokens[0].issuer, "Test")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentAccess_MultipleReads_Work() throws {
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)
        
        let expectation = expectation(description: "Concurrent reads complete")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        for _ in 0..<10 {
            queue.async {
                do {
                    _ = try KeychainService.loadVaultKey()
                    expectation.fulfill()
                } catch {
                    XCTFail("Concurrent read failed: \(error)")
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
