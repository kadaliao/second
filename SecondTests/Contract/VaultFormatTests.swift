import XCTest
@testable import Second

/// Contract tests for Vault Codable schema
/// Validates JSON encoding/decoding matches contracts/vault-format.json
final class VaultFormatTests: XCTestCase {

    func testVaultEncodesToJSON() throws {
        // Given: A Vault with tokens
        var vault = Vault()
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        )
        vault.addToken(token)

        // When: Encoding to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(vault)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Then: Schema matches contract
        XCTAssertNotNil(json["tokens"])
        XCTAssertEqual(json["version"] as? Int, 1)
        XCTAssertNotNil(json["lastModified"])

        let tokens = json["tokens"] as! [[String: Any]]
        XCTAssertEqual(tokens.count, 1)
    }

    func testEmptyVaultEncodesToJSON() throws {
        // Given: Empty vault
        let vault = Vault()

        // When: Encoding
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(vault)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Then: Empty tokens array valid
        let tokens = json["tokens"] as! [[String: Any]]
        XCTAssertEqual(tokens.count, 0)
        XCTAssertEqual(json["version"] as? Int, 1)
    }
}
