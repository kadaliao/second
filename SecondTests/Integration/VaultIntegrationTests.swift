import XCTest
@testable import Second

/// Integration test for end-to-end vault operations
final class VaultIntegrationTests: XCTestCase {

    func testEncryptSaveLoadDecrypt() throws {
        // Given: Services and vault
        let encryption = EncryptionService()
        let sync = iCloudSyncService()
        let key = SymmetricKey(size: .bits256)

        var vault = Vault()
        vault.addToken(Token(issuer: "Test", account: "test", secret: "JBSWY3DPEHPK3PXP"))

        // When: Encrypt → Save → Load → Decrypt
        let encoder = JSONEncoder()
        let plaintext = try encoder.encode(vault)
        let encrypted = try encryption.encrypt(plaintext, using: key)
        try sync.saveVault(encrypted)

        let loaded = try sync.loadVault()!
        let decrypted = try encryption.decrypt(loaded, using: key)
        let decoder = JSONDecoder()
        let restoredVault = try decoder.decode(Vault.self, from: decrypted)

        // Then: Vault restored correctly
        XCTAssertEqual(restoredVault.tokens.count, 1)
        XCTAssertEqual(restoredVault.tokens.first?.issuer, "Test")
    }
}
