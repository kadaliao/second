import XCTest
import CryptoKit
@testable import Second

/// Unit tests for AES-GCM encryption/decryption
final class EncryptionServiceTests: XCTestCase {

    func testEncryptDecryptRoundTrip() throws {
        // Given: Service and plaintext
        let service = EncryptionService()
        let key = SymmetricKey(size: .bits256)
        let plaintext = "Test vault data".data(using: .utf8)!

        // When: Encrypt then decrypt
        let encrypted = try service.encrypt(plaintext, using: key)
        let decrypted = try service.decrypt(encrypted, using: key)

        // Then: Matches original
        XCTAssertEqual(decrypted, plaintext)
    }

    func testEncryptProducesDifferentCiphertext() throws {
        // Given: Same plaintext encrypted twice
        let service = EncryptionService()
        let key = SymmetricKey(size: .bits256)
        let plaintext = "Test".data(using: .utf8)!

        // When: Encrypting twice
        let encrypted1 = try service.encrypt(plaintext, using: key)
        let encrypted2 = try service.encrypt(plaintext, using: key)

        // Then: Different (unique nonces)
        XCTAssertNotEqual(encrypted1, encrypted2)
    }

    func testDecryptWithWrongKeyFails() throws {
        // Given: Encrypted with one key
        let service = EncryptionService()
        let key1 = SymmetricKey(size: .bits256)
        let key2 = SymmetricKey(size: .bits256)
        let plaintext = "Test".data(using: .utf8)!
        let encrypted = try service.encrypt(plaintext, using: key1)

        // Then: Decrypting with wrong key throws
        XCTAssertThrowsError(try service.decrypt(encrypted, using: key2))
    }
}
