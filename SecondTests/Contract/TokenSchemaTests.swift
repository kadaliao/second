import XCTest
@testable import Second

/// Contract tests for Token Codable schema
/// Validates JSON encoding/decoding matches contracts/token-schema.json
final class TokenSchemaTests: XCTestCase {

    func testTokenEncodesToJSON() throws {
        // Given: A Token with all required fields
        let token = Token(
            id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30,
            algorithm: .sha1
        )

        // When: Encoding to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(token)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Then: All fields present and correct types
        XCTAssertNotNil(json["id"])
        XCTAssertEqual(json["issuer"] as? String, "GitHub")
        XCTAssertEqual(json["account"] as? String, "user@example.com")
        XCTAssertEqual(json["secret"] as? String, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(json["digits"] as? Int, 6)
        XCTAssertEqual(json["period"] as? Int, 30)
        XCTAssertEqual(json["algorithm"] as? String, "SHA1")
        XCTAssertNotNil(json["createdAt"])
        XCTAssertNotNil(json["updatedAt"])
    }

    func testTokenDecodesFromJSON() throws {
        // Given: Valid JSON matching schema
        let jsonString = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "issuer": "GitHub",
            "account": "user@example.com",
            "secret": "JBSWY3DPEHPK3PXP",
            "digits": 6,
            "period": 30,
            "algorithm": "SHA1",
            "createdAt": "2026-01-15T10:30:00Z",
            "updatedAt": "2026-01-15T10:30:00Z"
        }
        """

        // When: Decoding from JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let token = try decoder.decode(Token.self, from: jsonString.data(using: .utf8)!)

        // Then: Token created with correct values
        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "user@example.com")
        XCTAssertEqual(token.secret, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(token.digits, 6)
        XCTAssertEqual(token.period, 30)
        XCTAssertEqual(token.algorithm, .sha1)
    }
}
