//
//  TokenSchemaTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
@testable import Second

final class TokenSchemaTests: XCTestCase {
    
    var encoder: JSONEncoder!
    var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    override func tearDown() {
        encoder = nil
        decoder = nil
        super.tearDown()
    }
    
    // MARK: - Schema Structure Tests
    
    func testTokenSchema_HasRequiredFields() throws {
        let token = Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        
        let jsonData = try encoder.encode(token)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        
        // Required fields
        XCTAssertNotNil(json["id"], "Token must have id field")
        XCTAssertNotNil(json["issuer"], "Token must have issuer field")
        XCTAssertNotNil(json["account"], "Token must have account field")
        XCTAssertNotNil(json["secret"], "Token must have secret field")
        XCTAssertNotNil(json["digits"], "Token must have digits field")
        XCTAssertNotNil(json["period"], "Token must have period field")
        XCTAssertNotNil(json["algorithm"], "Token must have algorithm field")
        XCTAssertNotNil(json["createdAt"], "Token must have createdAt field")
        XCTAssertNotNil(json["updatedAt"], "Token must have updatedAt field")
    }
    
    func testTokenSchema_FieldTypes() throws {
        let token = Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        
        let jsonData = try encoder.encode(token)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        
        // Type validation
        XCTAssertTrue(json["id"] is String, "id must be string (UUID)")
        XCTAssertTrue(json["issuer"] is String, "issuer must be string")
        XCTAssertTrue(json["account"] is String, "account must be string")
        XCTAssertTrue(json["secret"] is String, "secret must be string")
        XCTAssertTrue(json["digits"] is Int, "digits must be integer")
        XCTAssertTrue(json["period"] is Int, "period must be integer")
        XCTAssertTrue(json["algorithm"] is String, "algorithm must be string")
        XCTAssertTrue(json["createdAt"] is String, "createdAt must be ISO8601 string")
        XCTAssertTrue(json["updatedAt"] is String, "updatedAt must be ISO8601 string")
    }
    
    func testTokenSchema_IDFormat_IsValidUUID() throws {
        let token = Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        
        let jsonData = try encoder.encode(token)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        let idString = json["id"] as! String
        
        // Should be valid UUID format
        XCTAssertNotNil(UUID(uuidString: idString), "id must be valid UUID format")
    }
    
    func testTokenSchema_AlgorithmValues_AreValid() throws {
        let algorithms: [TOTPParameters.Algorithm] = [.sha1, .sha256, .sha512]
        let expectedValues = ["sha1", "sha256", "sha512"]
        
        for (algorithm, expectedValue) in zip(algorithms, expectedValues) {
            let token = Token(
                issuer: "Test",
                account: "test@test.com",
                secret: "JBSWY3DPEHPK3PXP",
                digits: 6,
                period: 30,
                algorithm: algorithm
            )
            
            let jsonData = try encoder.encode(token)
            let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            let algorithmString = json["algorithm"] as! String
            
            XCTAssertEqual(algorithmString, expectedValue, "Algorithm should serialize to '\(expectedValue)'")
        }
    }
    
    func testTokenSchema_DateFormat_IsISO8601() throws {
        let token = Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        
        let jsonData = try encoder.encode(token)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        let createdAtString = json["createdAt"] as! String
        
        // ISO8601 format should contain 'T' and 'Z'
        XCTAssertTrue(createdAtString.contains("T"), "Date should be in ISO8601 format with 'T'")
        XCTAssertTrue(createdAtString.contains("Z"), "Date should be in ISO8601 format with 'Z'")
        
        // Should be parseable by ISO8601DateFormatter
        let formatter = ISO8601DateFormatter()
        XCTAssertNotNil(formatter.date(from: createdAtString), "Date should be valid ISO8601")
    }
    
    // MARK: - Value Constraints Tests
    
    func testTokenSchema_Digits_ValidRange() throws {
        // Test valid digit values: 6, 7, 8
        for digits in [6, 7, 8] {
            let token = Token(
                issuer: "Test",
                account: "test@test.com",
                secret: "JBSWY3DPEHPK3PXP",
                digits: digits
            )
            
            let jsonData = try encoder.encode(token)
            let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            let digitsValue = json["digits"] as! Int
            
            XCTAssertEqual(digitsValue, digits)
            XCTAssertGreaterThanOrEqual(digitsValue, 6)
            XCTAssertLessThanOrEqual(digitsValue, 8)
        }
    }
    
    func testTokenSchema_Period_PositiveValue() throws {
        let token = Token(
            issuer: "Test",
            account: "test@test.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30
        )
        
        let jsonData = try encoder.encode(token)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        let periodValue = json["period"] as! Int
        
        XCTAssertGreaterThan(periodValue, 0, "Period must be positive")
    }
    
    func testTokenSchema_Secret_NotEmpty() throws {
        let token = Token(issuer: "Test", account: "test@test.com", secret: "JBSWY3DPEHPK3PXP")
        
        let jsonData = try encoder.encode(token)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        let secretValue = json["secret"] as! String
        
        XCTAssertFalse(secretValue.isEmpty, "Secret must not be empty")
    }
    
    // MARK: - Serialization Round-Trip Tests
    
    func testTokenSchema_RoundTrip_PreservesAllFields() throws {
        let original = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 8,
            period: 60,
            algorithm: .sha256
        )
        
        let jsonData = try encoder.encode(original)
        let decoded = try decoder.decode(Token.self, from: jsonData)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.issuer, original.issuer)
        XCTAssertEqual(decoded.account, original.account)
        XCTAssertEqual(decoded.secret, original.secret)
        XCTAssertEqual(decoded.digits, original.digits)
        XCTAssertEqual(decoded.period, original.period)
        XCTAssertEqual(decoded.algorithm, original.algorithm)
    }
    
    func testTokenSchema_RoundTrip_WithUnicodeCharacters() throws {
        let original = Token(
            issuer: "测试公司 🔐",
            account: "用户@例子.com",
            secret: "JBSWY3DPEHPK3PXP"
        )
        
        let jsonData = try encoder.encode(original)
        let decoded = try decoder.decode(Token.self, from: jsonData)
        
        XCTAssertEqual(decoded.issuer, original.issuer)
        XCTAssertEqual(decoded.account, original.account)
    }
    
    // MARK: - Backward Compatibility Tests
    
    func testTokenSchema_CanDecodeMinimalJSON() throws {
        let minimalJSON = """
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
        """
        
        let jsonData = minimalJSON.data(using: .utf8)!
        let token = try decoder.decode(Token.self, from: jsonData)
        
        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "user@example.com")
        XCTAssertEqual(token.secret, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(token.digits, 6)
        XCTAssertEqual(token.period, 30)
        XCTAssertEqual(token.algorithm, .sha1)
    }
    
    func testTokenSchema_CanDecodeAllAlgorithms() throws {
        let algorithms = ["sha1", "sha256", "sha512"]
        let expected: [TOTPParameters.Algorithm] = [.sha1, .sha256, .sha512]
        
        for (algorithmString, expectedAlgorithm) in zip(algorithms, expected) {
            let jsonString = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "issuer": "Test",
                "account": "test@test.com",
                "secret": "JBSWY3DPEHPK3PXP",
                "digits": 6,
                "period": 30,
                "algorithm": "\(algorithmString)",
                "createdAt": "2024-01-01T00:00:00Z",
                "updatedAt": "2024-01-01T00:00:00Z"
            }
            """
            
            let jsonData = jsonString.data(using: .utf8)!
            let token = try decoder.decode(Token.self, from: jsonData)
            
            XCTAssertEqual(token.algorithm, expectedAlgorithm)
        }
    }
    
    // MARK: - JSON Structure Tests
    
    func testTokenSchema_JSONKeys_AreCamelCase() throws {
        let token = Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        
        let jsonData = try encoder.encode(token)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Keys should be camelCase
        XCTAssertTrue(jsonString.contains("\"issuer\""))
        XCTAssertTrue(jsonString.contains("\"account\""))
        XCTAssertTrue(jsonString.contains("\"secret\""))
        XCTAssertTrue(jsonString.contains("\"digits\""))
        XCTAssertTrue(jsonString.contains("\"period\""))
        XCTAssertTrue(jsonString.contains("\"algorithm\""))
        XCTAssertTrue(jsonString.contains("\"createdAt\""))
        XCTAssertTrue(jsonString.contains("\"updatedAt\""))
        
        // Should NOT be snake_case
        XCTAssertFalse(jsonString.contains("created_at"))
        XCTAssertFalse(jsonString.contains("updated_at"))
    }
    
    func testTokenSchema_JSONOutput_IsValidJSON() throws {
        let token = Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP")
        
        let jsonData = try encoder.encode(token)
        
        // Should be parseable as JSON
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: jsonData))
    }
    
    // MARK: - Error Cases
    
    func testTokenSchema_InvalidAlgorithm_ThrowsError() {
        let invalidJSON = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "issuer": "Test",
            "account": "test@test.com",
            "secret": "JBSWY3DPEHPK3PXP",
            "digits": 6,
            "period": 30,
            "algorithm": "md5",
            "createdAt": "2024-01-01T00:00:00Z",
            "updatedAt": "2024-01-01T00:00:00Z"
        }
        """
        
        let jsonData = invalidJSON.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(Token.self, from: jsonData))
    }
    
    func testTokenSchema_MissingRequiredField_ThrowsError() {
        let invalidJSON = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "issuer": "Test",
            "account": "test@test.com"
        }
        """
        
        let jsonData = invalidJSON.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(Token.self, from: jsonData))
    }
    
    func testTokenSchema_InvalidUUID_ThrowsError() {
        let invalidJSON = """
        {
            "id": "not-a-valid-uuid",
            "issuer": "Test",
            "account": "test@test.com",
            "secret": "JBSWY3DPEHPK3PXP",
            "digits": 6,
            "period": 30,
            "algorithm": "sha1",
            "createdAt": "2024-01-01T00:00:00Z",
            "updatedAt": "2024-01-01T00:00:00Z"
        }
        """
        
        let jsonData = invalidJSON.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(Token.self, from: jsonData))
    }
}
