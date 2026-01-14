//
//  TokenTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
@testable import Second

final class TokenTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInit_ValidData_CreatesToken() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        )
        
        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "user@example.com")
        XCTAssertEqual(token.secret, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(token.digits, 6)
        XCTAssertEqual(token.period, 30)
        XCTAssertEqual(token.algorithm, .sha1)
    }
    
    func testInit_CustomParameters_CreatesToken() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 8,
            period: 60,
            algorithm: .sha256
        )
        
        XCTAssertEqual(token.digits, 8)
        XCTAssertEqual(token.period, 60)
        XCTAssertEqual(token.algorithm, .sha256)
    }
    
    func testInit_TrimsWhitespace_InIssuer() {
        let token = Token(
            issuer: "  GitHub  ",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        )
        
        XCTAssertEqual(token.issuer, "GitHub")
    }
    
    func testInit_TrimsWhitespace_InAccount() {
        let token = Token(
            issuer: "GitHub",
            account: "  user@example.com  ",
            secret: "JBSWY3DPEHPK3PXP"
        )
        
        XCTAssertEqual(token.account, "user@example.com")
    }
    
    func testInit_GeneratesUniqueID() {
        let token1 = Token(issuer: "Test", account: "test", secret: "JBSWY3DPEHPK3PXP")
        let token2 = Token(issuer: "Test", account: "test", secret: "JBSWY3DPEHPK3PXP")
        
        XCTAssertNotEqual(token1.id, token2.id, "Each token should have unique ID")
    }
    
    func testInit_SetsTimestamps() {
        let before = Date()
        let token = Token(issuer: "Test", account: "test", secret: "JBSWY3DPEHPK3PXP")
        let after = Date()
        
        XCTAssertGreaterThanOrEqual(token.createdAt, before)
        XCTAssertLessThanOrEqual(token.createdAt, after)
        XCTAssertEqual(token.createdAt, token.updatedAt)
    }
    
    // MARK: - Validation Tests
    
    func testValidate_ValidToken_DoesNotThrow() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        )
        
        XCTAssertNoThrow(try token.validate())
    }
    
    func testValidate_EmptyIssuer_ThrowsError() {
        let token = Token(
            issuer: "",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        )
        
        XCTAssertThrowsError(try token.validate()) { error in
            guard case Token.ValidationError.emptyIssuer = error else {
                XCTFail("Expected emptyIssuer error")
                return
            }
        }
    }
    
    func testValidate_WhitespaceOnlyIssuer_ThrowsError() {
        let token = Token(
            issuer: "   ",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        )
        
        XCTAssertThrowsError(try token.validate()) { error in
            guard case Token.ValidationError.emptyIssuer = error else {
                XCTFail("Expected emptyIssuer error")
                return
            }
        }
    }
    
    func testValidate_EmptyAccount_ThrowsError() {
        let token = Token(
            issuer: "GitHub",
            account: "",
            secret: "JBSWY3DPEHPK3PXP"
        )
        
        XCTAssertThrowsError(try token.validate()) { error in
            guard case Token.ValidationError.emptyAccount = error else {
                XCTFail("Expected emptyAccount error")
                return
            }
        }
    }
    
    func testValidate_InvalidDigits_ThrowsError() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 4
        )
        
        XCTAssertThrowsError(try token.validate()) { error in
            guard case Token.ValidationError.invalidDigits = error else {
                XCTFail("Expected invalidDigits error")
                return
            }
        }
    }
    
    func testValidate_InvalidPeriod_ThrowsError() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: -30
        )
        
        XCTAssertThrowsError(try token.validate()) { error in
            guard case Token.ValidationError.invalidPeriod = error else {
                XCTFail("Expected invalidPeriod error")
                return
            }
        }
    }
    
    func testValidate_ZeroPeriod_ThrowsError() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 0
        )
        
        XCTAssertThrowsError(try token.validate()) { error in
            guard case Token.ValidationError.invalidPeriod = error else {
                XCTFail("Expected invalidPeriod error")
                return
            }
        }
    }
    
    // MARK: - Codable Tests
    
    func testCodable_EncodeDecode_PreservesData() throws {
        let original = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 8,
            period: 60,
            algorithm: .sha256
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Token.self, from: encoded)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.issuer, original.issuer)
        XCTAssertEqual(decoded.account, original.account)
        XCTAssertEqual(decoded.secret, original.secret)
        XCTAssertEqual(decoded.digits, original.digits)
        XCTAssertEqual(decoded.period, original.period)
        XCTAssertEqual(decoded.algorithm, original.algorithm)
    }
    
    // MARK: - Equatable Tests
    
    func testEquatable_SameID_AreEqual() {
        let id = UUID()
        let token1 = Token(
            id: id,
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        )
        let token2 = Token(
            id: id,
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        )
        
        XCTAssertEqual(token1, token2)
    }
    
    func testEquatable_DifferentID_AreNotEqual() {
        let token1 = Token(issuer: "GitHub", account: "user", secret: "JBSWY3DPEHPK3PXP")
        let token2 = Token(issuer: "GitHub", account: "user", secret: "JBSWY3DPEHPK3PXP")
        
        XCTAssertNotEqual(token1, token2)
    }
}
