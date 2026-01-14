//
//  EncryptionServiceTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
import CryptoKit
@testable import Second

final class EncryptionServiceTests: XCTestCase {
    
    var testKey: SymmetricKey!
    var testVault: Vault!
    
    override func setUp() {
        super.setUp()
        testKey = SymmetricKey(size: .bits256)
        testVault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "GEZDGNBVGY3TQOJQ")
        ])
    }
    
    override func tearDown() {
        testKey = nil
        testVault = nil
        super.tearDown()
    }
    
    // MARK: - Encryption Tests
    
    func testEncrypt_ValidVault_ReturnsData() throws {
        let encrypted = try EncryptionService.encrypt(vault: testVault, using: testKey)
        
        XCTAssertGreaterThan(encrypted.count, 0, "Encrypted data should not be empty")
    }
    
    func testEncrypt_EmptyVault_ReturnsData() throws {
        let emptyVault = Vault(tokens: [])
        let encrypted = try EncryptionService.encrypt(vault: emptyVault, using: testKey)
        
        XCTAssertGreaterThan(encrypted.count, 0, "Even empty vault should encrypt to non-empty data")
    }
    
    func testEncrypt_SameVault_ReturnsDifferentData() throws {
        // AES-GCM uses random nonce, so same plaintext should encrypt to different ciphertext
        let encrypted1 = try EncryptionService.encrypt(vault: testVault, using: testKey)
        let encrypted2 = try EncryptionService.encrypt(vault: testVault, using: testKey)
        
        XCTAssertNotEqual(encrypted1, encrypted2, "Same vault should encrypt to different ciphertext (different nonces)")
    }
    
    // MARK: - Decryption Tests
    
    func testDecrypt_ValidEncryptedData_ReturnsOriginalVault() throws {
        let encrypted = try EncryptionService.encrypt(vault: testVault, using: testKey)
        let decrypted = try EncryptionService.decrypt(encryptedData: encrypted, using: testKey)
        
        XCTAssertEqual(decrypted.tokens.count, testVault.tokens.count, "Decrypted vault should have same token count")
        XCTAssertEqual(decrypted.tokens[0].issuer, testVault.tokens[0].issuer)
        XCTAssertEqual(decrypted.tokens[0].account, testVault.tokens[0].account)
        XCTAssertEqual(decrypted.tokens[0].secret, testVault.tokens[0].secret)
    }
    
    func testDecrypt_EmptyVault_ReturnsEmptyVault() throws {
        let emptyVault = Vault(tokens: [])
        let encrypted = try EncryptionService.encrypt(vault: emptyVault, using: testKey)
        let decrypted = try EncryptionService.decrypt(encryptedData: encrypted, using: testKey)
        
        XCTAssertEqual(decrypted.tokens.count, 0, "Empty vault should decrypt to empty vault")
    }
    
    // MARK: - Round-Trip Tests
    
    func testRoundTrip_EncryptAndDecrypt_PreservesData() throws {
        // Encrypt
        let encrypted = try EncryptionService.encrypt(vault: testVault, using: testKey)
        
        // Decrypt
        let decrypted = try EncryptionService.decrypt(encryptedData: encrypted, using: testKey)
        
        // Verify all tokens
        XCTAssertEqual(decrypted.tokens.count, 2)
        
        let token1 = decrypted.tokens[0]
        XCTAssertEqual(token1.issuer, "GitHub")
        XCTAssertEqual(token1.account, "user@example.com")
        XCTAssertEqual(token1.secret, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(token1.digits, 6)
        XCTAssertEqual(token1.period, 30)
        XCTAssertEqual(token1.algorithm, .sha1)
        
        let token2 = decrypted.tokens[1]
        XCTAssertEqual(token2.issuer, "Google")
        XCTAssertEqual(token2.account, "user@gmail.com")
        XCTAssertEqual(token2.secret, "GEZDGNBVGY3TQOJQ")
    }
    
    func testRoundTrip_MultipleTokens_PreservesOrder() throws {
        let vault = Vault(tokens: [
            Token(issuer: "A", account: "a", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "B", account: "b", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "C", account: "c", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let encrypted = try EncryptionService.encrypt(vault: vault, using: testKey)
        let decrypted = try EncryptionService.decrypt(encryptedData: encrypted, using: testKey)
        
        XCTAssertEqual(decrypted.tokens.count, 3)
        XCTAssertEqual(decrypted.tokens[0].issuer, "A")
        XCTAssertEqual(decrypted.tokens[1].issuer, "B")
        XCTAssertEqual(decrypted.tokens[2].issuer, "C")
    }
    
    // MARK: - Error Cases
    
    func testDecrypt_WrongKey_ThrowsError() throws {
        let encrypted = try EncryptionService.encrypt(vault: testVault, using: testKey)
        
        // Try to decrypt with different key
        let wrongKey = SymmetricKey(size: .bits256)
        
        XCTAssertThrowsError(try EncryptionService.decrypt(encryptedData: encrypted, using: wrongKey)) { error in
            // Should throw CryptoKit authentication failure or decryption error
            XCTAssertTrue(error is CryptoKitError || error is EncryptionService.EncryptionError)
        }
    }
    
    func testDecrypt_CorruptedData_ThrowsError() {
        let corruptedData = Data([0x00, 0x01, 0x02, 0x03])
        
        XCTAssertThrowsError(try EncryptionService.decrypt(encryptedData: corruptedData, using: testKey)) { error in
            XCTAssertTrue(error is CryptoKitError || error is EncryptionService.EncryptionError)
        }
    }
    
    func testDecrypt_EmptyData_ThrowsError() {
        let emptyData = Data()
        
        XCTAssertThrowsError(try EncryptionService.decrypt(encryptedData: emptyData, using: testKey))
    }
    
    // MARK: - Data Integrity Tests
    
    func testEncrypt_ModifiedCiphertext_FailsDecryption() throws {
        var encrypted = try EncryptionService.encrypt(vault: testVault, using: testKey)
        
        // Modify one byte in the middle
        let middleIndex = encrypted.count / 2
        encrypted[middleIndex] ^= 0xFF
        
        // Should fail authentication
        XCTAssertThrowsError(try EncryptionService.decrypt(encryptedData: encrypted, using: testKey))
    }
    
    // MARK: - Special Characters Tests
    
    func testRoundTrip_SpecialCharactersInIssuer_PreservesData() throws {
        let vault = Vault(tokens: [
            Token(issuer: "Test & Co. (2024)", account: "user@test.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let encrypted = try EncryptionService.encrypt(vault: vault, using: testKey)
        let decrypted = try EncryptionService.decrypt(encryptedData: encrypted, using: testKey)
        
        XCTAssertEqual(decrypted.tokens[0].issuer, "Test & Co. (2024)")
    }
    
    func testRoundTrip_UnicodeCharacters_PreservesData() throws {
        let vault = Vault(tokens: [
            Token(issuer: "测试公司", account: "用户@例子.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let encrypted = try EncryptionService.encrypt(vault: vault, using: testKey)
        let decrypted = try EncryptionService.decrypt(encryptedData: encrypted, using: testKey)
        
        XCTAssertEqual(decrypted.tokens[0].issuer, "测试公司")
        XCTAssertEqual(decrypted.tokens[0].account, "用户@例子.com")
    }
    
    func testRoundTrip_EmojisInData_PreservesData() throws {
        let vault = Vault(tokens: [
            Token(issuer: "Test 🔐", account: "user@test.com 🚀", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let encrypted = try EncryptionService.encrypt(vault: vault, using: testKey)
        let decrypted = try EncryptionService.decrypt(encryptedData: encrypted, using: testKey)
        
        XCTAssertEqual(decrypted.tokens[0].issuer, "Test 🔐")
        XCTAssertEqual(decrypted.tokens[0].account, "user@test.com 🚀")
    }
    
    // MARK: - Performance Tests
    
    func testEncryptionPerformance() {
        let largeVault = Vault(tokens: Array(repeating: Token(
            issuer: "Test",
            account: "test@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        ), count: 50))
        
        measure {
            for _ in 0..<100 {
                _ = try? EncryptionService.encrypt(vault: largeVault, using: testKey)
            }
        }
        
        // Should complete < 200ms per encryption (requirement)
    }
    
    func testDecryptionPerformance() throws {
        let largeVault = Vault(tokens: Array(repeating: Token(
            issuer: "Test",
            account: "test@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        ), count: 50))
        
        let encrypted = try EncryptionService.encrypt(vault: largeVault, using: testKey)
        
        measure {
            for _ in 0..<100 {
                _ = try? EncryptionService.decrypt(encryptedData: encrypted, using: testKey)
            }
        }
        
        // Should complete < 200ms per decryption (requirement)
    }
}
