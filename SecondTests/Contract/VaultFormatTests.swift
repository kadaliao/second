//
//  VaultFormatTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
import CryptoKit
@testable import Second

final class VaultFormatTests: XCTestCase {
    
    var encoder: JSONEncoder!
    var decoder: JSONDecoder!
    var testKey: SymmetricKey!
    
    override func setUp() {
        super.setUp()
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        testKey = SymmetricKey(size: .bits256)
    }
    
    override func tearDown() {
        encoder = nil
        decoder = nil
        testKey = nil
        super.tearDown()
    }
    
    // MARK: - Vault Schema Tests
    
    func testVaultSchema_HasRequiredFields() throws {
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let jsonData = try encoder.encode(vault)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        
        XCTAssertNotNil(json["tokens"], "Vault must have tokens field")
    }
    
    func testVaultSchema_TokensIsArray() throws {
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let jsonData = try encoder.encode(vault)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        
        XCTAssertTrue(json["tokens"] is [[String: Any]], "tokens must be an array")
    }
    
    func testVaultSchema_EmptyVault_HasEmptyArray() throws {
        let vault = Vault(tokens: [])
        
        let jsonData = try encoder.encode(vault)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        let tokens = json["tokens"] as! [[String: Any]]
        
        XCTAssertEqual(tokens.count, 0, "Empty vault should have empty tokens array")
    }
    
    // MARK: - Encrypted Format Tests
    
    func testEncryptedFormat_NotEmptyData() throws {
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: testKey)
        
        XCTAssertGreaterThan(encryptedData.count, 0, "Encrypted data must not be empty")
    }
    
    func testEncryptedFormat_MinimumSize() throws {
        // Even empty vault should produce encrypted data with nonce + tag
        let vault = Vault(tokens: [])
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: testKey)
        
        // AES-GCM produces: nonce (12 bytes) + ciphertext + tag (16 bytes)
        // Minimum size should be at least 28 bytes
        XCTAssertGreaterThanOrEqual(encryptedData.count, 28, "Encrypted data should include nonce and tag")
    }
    
    func testEncryptedFormat_ContainsBinaryData() throws {
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: testKey)
        
        // Encrypted data should not be valid UTF-8 text (it's binary)
        XCTAssertNil(String(data: encryptedData, encoding: .utf8), "Encrypted data should be binary, not UTF-8 text")
    }
    
    func testEncryptedFormat_DifferentNonces() throws {
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let encrypted1 = try EncryptionService.encrypt(vault: vault, using: testKey)
        let encrypted2 = try EncryptionService.encrypt(vault: vault, using: testKey)
        
        // Same plaintext should produce different ciphertext (different nonces)
        XCTAssertNotEqual(encrypted1, encrypted2, "Encryption should use random nonces")
    }
    
    // MARK: - Decryption Format Tests
    
    func testDecryptedFormat_ProducesValidVault() throws {
        let originalVault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let encryptedData = try EncryptionService.encrypt(vault: originalVault, using: testKey)
        let decryptedVault = try EncryptionService.decrypt(encryptedData: encryptedData, using: testKey)
        
        XCTAssertNotNil(decryptedVault.tokens)
        XCTAssertEqual(decryptedVault.tokens.count, 1)
    }
    
    func testDecryptedFormat_PreservesTokenOrder() throws {
        let tokens = [
            Token(issuer: "A", account: "a@test.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "B", account: "b@test.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "C", account: "c@test.com", secret: "JBSWY3DPEHPK3PXP")
        ]
        let originalVault = Vault(tokens: tokens)
        
        let encryptedData = try EncryptionService.encrypt(vault: originalVault, using: testKey)
        let decryptedVault = try EncryptionService.decrypt(encryptedData: encryptedData, using: testKey)
        
        for (index, token) in decryptedVault.tokens.enumerated() {
            XCTAssertEqual(token.issuer, tokens[index].issuer, "Token order should be preserved")
        }
    }
    
    // MARK: - JSON Structure Tests
    
    func testVaultJSON_Structure() throws {
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "GEZDGNBVGY3TQOJQ")
        ])
        
        let jsonData = try encoder.encode(vault)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Should contain tokens array
        XCTAssertTrue(jsonString.contains("\"tokens\""))
        
        // Should contain token data
        XCTAssertTrue(jsonString.contains("GitHub"))
        XCTAssertTrue(jsonString.contains("Google"))
    }
    
    func testVaultJSON_IsValidJSON() throws {
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let jsonData = try encoder.encode(vault)
        
        // Should be parseable as JSON
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: jsonData))
    }
    
    // MARK: - Round-Trip Tests
    
    func testVaultRoundTrip_SingleToken() throws {
        let original = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let jsonData = try encoder.encode(original)
        let decoded = try decoder.decode(Vault.self, from: jsonData)
        
        XCTAssertEqual(decoded.tokens.count, original.tokens.count)
        XCTAssertEqual(decoded.tokens[0].issuer, original.tokens[0].issuer)
    }
    
    func testVaultRoundTrip_MultipleTokens() throws {
        let original = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "GEZDGNBVGY3TQOJQ", digits: 8, period: 60, algorithm: .sha256),
            Token(issuer: "Microsoft", account: "user@outlook.com", secret: "MFRGGZDFMZTWQ2LK")
        ])
        
        let jsonData = try encoder.encode(original)
        let decoded = try decoder.decode(Vault.self, from: jsonData)
        
        XCTAssertEqual(decoded.tokens.count, 3)
        XCTAssertEqual(decoded.tokens[0].issuer, "GitHub")
        XCTAssertEqual(decoded.tokens[1].issuer, "Google")
        XCTAssertEqual(decoded.tokens[1].digits, 8)
        XCTAssertEqual(decoded.tokens[1].algorithm, .sha256)
        XCTAssertEqual(decoded.tokens[2].issuer, "Microsoft")
    }
    
    func testVaultRoundTrip_EmptyVault() throws {
        let original = Vault(tokens: [])
        
        let jsonData = try encoder.encode(original)
        let decoded = try decoder.decode(Vault.self, from: jsonData)
        
        XCTAssertEqual(decoded.tokens.count, 0)
    }
    
    // MARK: - Encrypted Round-Trip Tests
    
    func testEncryptedVaultRoundTrip_PreservesData() throws {
        let original = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let encryptedData = try EncryptionService.encrypt(vault: original, using: testKey)
        let decrypted = try EncryptionService.decrypt(encryptedData: encryptedData, using: testKey)
        
        XCTAssertEqual(decrypted.tokens.count, original.tokens.count)
        XCTAssertEqual(decrypted.tokens[0].id, original.tokens[0].id)
        XCTAssertEqual(decrypted.tokens[0].issuer, original.tokens[0].issuer)
        XCTAssertEqual(decrypted.tokens[0].secret, original.tokens[0].secret)
    }
    
    func testEncryptedVaultRoundTrip_50Tokens() throws {
        let tokens = (0..<50).map { index in
            Token(
                issuer: "Service\(index)",
                account: "user\(index)@example.com",
                secret: "JBSWY3DPEHPK3PXP"
            )
        }
        let original = Vault(tokens: tokens)
        
        let encryptedData = try EncryptionService.encrypt(vault: original, using: testKey)
        let decrypted = try EncryptionService.decrypt(encryptedData: encryptedData, using: testKey)
        
        XCTAssertEqual(decrypted.tokens.count, 50)
        for (index, token) in decrypted.tokens.enumerated() {
            XCTAssertEqual(token.issuer, "Service\(index)")
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testEncryptedVault_AuthenticationTag_DetectsModification() throws {
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        var encryptedData = try EncryptionService.encrypt(vault: vault, using: testKey)
        
        // Modify one byte
        let middleIndex = encryptedData.count / 2
        encryptedData[middleIndex] ^= 0xFF
        
        // Should fail to decrypt due to authentication failure
        XCTAssertThrowsError(try EncryptionService.decrypt(encryptedData: encryptedData, using: testKey))
    }
    
    func testEncryptedVault_WrongKey_FailsDecryption() throws {
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        ])
        
        let key1 = SymmetricKey(size: .bits256)
        let key2 = SymmetricKey(size: .bits256)
        
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key1)
        
        // Should fail with wrong key
        XCTAssertThrowsError(try EncryptionService.decrypt(encryptedData: encryptedData, using: key2))
    }
    
    // MARK: - Special Characters Tests
    
    func testVaultFormat_UnicodeCharacters_Preserved() throws {
        let vault = Vault(tokens: [
            Token(issuer: "测试公司", account: "用户@例子.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Test 🔐", account: "user@test.com", secret: "GEZDGNBVGY3TQOJQ")
        ])
        
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: testKey)
        let decrypted = try EncryptionService.decrypt(encryptedData: encryptedData, using: testKey)
        
        XCTAssertEqual(decrypted.tokens[0].issuer, "测试公司")
        XCTAssertEqual(decrypted.tokens[0].account, "用户@例子.com")
        XCTAssertEqual(decrypted.tokens[1].issuer, "Test 🔐")
    }
    
    // MARK: - Backward Compatibility Tests
    
    func testVaultFormat_CanDecodeMinimalJSON() throws {
        let minimalJSON = """
        {
            "tokens": [
                {
                    "id": "550e8400-e29b-41d4-a716-446655440000",
                    "issuer": "GitHub",
                    "account": "user@example.com",
                    "secret": "JBSWY3DPEHPK3PXP",
                    "digits": 6,
                    "period": 30,
                    "algorithm": "sha1",
                    "createdAt": "2024-01-01T00:00:00Z",
                    "updatedAt": "2024-01-01T00:00:00Z"
                }
            ]
        }
        """
        
        let jsonData = minimalJSON.data(using: .utf8)!
        let vault = try decoder.decode(Vault.self, from: jsonData)
        
        XCTAssertEqual(vault.tokens.count, 1)
        XCTAssertEqual(vault.tokens[0].issuer, "GitHub")
    }
    
    func testVaultFormat_CanDecodeEmptyTokensArray() throws {
        let emptyJSON = """
        {
            "tokens": []
        }
        """
        
        let jsonData = emptyJSON.data(using: .utf8)!
        let vault = try decoder.decode(Vault.self, from: jsonData)
        
        XCTAssertEqual(vault.tokens.count, 0)
    }
    
    // MARK: - Error Cases
    
    func testVaultFormat_MissingTokensField_ThrowsError() {
        let invalidJSON = """
        {
            "notTokens": []
        }
        """
        
        let jsonData = invalidJSON.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(Vault.self, from: jsonData))
    }
    
    func testVaultFormat_InvalidTokenData_ThrowsError() {
        let invalidJSON = """
        {
            "tokens": [
                {
                    "issuer": "Test"
                }
            ]
        }
        """
        
        let jsonData = invalidJSON.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(Vault.self, from: jsonData))
    }
}
