//
//  TOTPGeneratorTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
@testable import Second

final class TOTPGeneratorTests: XCTestCase {
    
    // MARK: - RFC 6238 Test Vectors (Appendix B)
    
    func testGenerate_RFC6238_SHA1_Time59_Returns94287082() {
        // Test vector from RFC 6238
        let token = Token(
            issuer: "Test",
            account: "test@example.com",
            secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
            digits: 8,
            period: 30,
            algorithm: .sha1
        )
        
        let date = Date(timeIntervalSince1970: 59)
        let code = TOTPGenerator.generate(token: token, time: date)
        
        XCTAssertEqual(code, "94287082", "RFC 6238 test vector failed for SHA1 at time 59")
    }
    
    func testGenerate_RFC6238_SHA1_Time1111111109_Returns07081804() {
        let token = Token(
            issuer: "Test",
            account: "test@example.com",
            secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
            digits: 8,
            period: 30,
            algorithm: .sha1
        )
        
        let date = Date(timeIntervalSince1970: 1111111109)
        let code = TOTPGenerator.generate(token: token, time: date)
        
        XCTAssertEqual(code, "07081804", "RFC 6238 test vector failed for SHA1 at time 1111111109")
    }
    
    func testGenerate_RFC6238_SHA1_Time1111111111_Returns14050471() {
        let token = Token(
            issuer: "Test",
            account: "test@example.com",
            secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
            digits: 8,
            period: 30,
            algorithm: .sha1
        )
        
        let date = Date(timeIntervalSince1970: 1111111111)
        let code = TOTPGenerator.generate(token: token, time: date)
        
        XCTAssertEqual(code, "14050471", "RFC 6238 test vector failed for SHA1 at time 1111111111")
    }
    
    func testGenerate_RFC6238_SHA1_Time1234567890_Returns89005924() {
        let token = Token(
            issuer: "Test",
            account: "test@example.com",
            secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
            digits: 8,
            period: 30,
            algorithm: .sha1
        )
        
        let date = Date(timeIntervalSince1970: 1234567890)
        let code = TOTPGenerator.generate(token: token, time: date)
        
        XCTAssertEqual(code, "89005924", "RFC 6238 test vector failed for SHA1 at time 1234567890")
    }
    
    // MARK: - 6-Digit Code Tests
    
    func testGenerate_6Digits_ReturnsCorrectLength() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30,
            algorithm: .sha1
        )
        
        let code = TOTPGenerator.generate(token: token)
        
        XCTAssertNotNil(code, "Code should not be nil")
        XCTAssertEqual(code?.count, 6, "6-digit code should have length 6")
    }
    
    func testGenerate_6Digits_ContainsOnlyDigits() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30,
            algorithm: .sha1
        )
        
        let code = TOTPGenerator.generate(token: token)
        
        XCTAssertNotNil(code)
        XCTAssertTrue(code!.allSatisfy { $0.isNumber }, "Code should contain only digits")
    }
    
    // MARK: - 8-Digit Code Tests
    
    func testGenerate_8Digits_ReturnsCorrectLength() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 8,
            period: 30,
            algorithm: .sha1
        )
        
        let code = TOTPGenerator.generate(token: token)
        
        XCTAssertNotNil(code)
        XCTAssertEqual(code?.count, 8, "8-digit code should have length 8")
    }
    
    // MARK: - Algorithm Tests
    
    func testGenerate_SHA256_ReturnsValidCode() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30,
            algorithm: .sha256
        )
        
        let code = TOTPGenerator.generate(token: token)
        
        XCTAssertNotNil(code, "SHA256 should generate valid code")
        XCTAssertEqual(code?.count, 6)
    }
    
    func testGenerate_SHA512_ReturnsValidCode() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30,
            algorithm: .sha512
        )
        
        let code = TOTPGenerator.generate(token: token)
        
        XCTAssertNotNil(code, "SHA512 should generate valid code")
        XCTAssertEqual(code?.count, 6)
    }
    
    // MARK: - Time Period Tests
    
    func testGenerate_CustomPeriod60_ReturnsValidCode() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 60,
            algorithm: .sha1
        )
        
        let code = TOTPGenerator.generate(token: token)
        
        XCTAssertNotNil(code, "Custom period should work")
        XCTAssertEqual(code?.count, 6)
    }
    
    // MARK: - Time Remaining Tests
    
    func testTimeRemaining_StartOfPeriod_Returns30() {
        let token = Token(
            issuer: "Test",
            account: "test",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30
        )
        
        // Time at exact start of period (divisible by 30)
        let date = Date(timeIntervalSince1970: 60)
        let remaining = TOTPGenerator.timeRemaining(for: token, at: date)
        
        XCTAssertEqual(remaining, 30, "At start of period, should have 30 seconds remaining")
    }
    
    func testTimeRemaining_MiddleOfPeriod_Returns15() {
        let token = Token(
            issuer: "Test",
            account: "test",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30
        )
        
        // 15 seconds into period
        let date = Date(timeIntervalSince1970: 75)
        let remaining = TOTPGenerator.timeRemaining(for: token, at: date)
        
        XCTAssertEqual(remaining, 15, "At middle of period, should have 15 seconds remaining")
    }
    
    func testTimeRemaining_EndOfPeriod_Returns1() {
        let token = Token(
            issuer: "Test",
            account: "test",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30
        )
        
        // 29 seconds into period (1 second before next period)
        let date = Date(timeIntervalSince1970: 89)
        let remaining = TOTPGenerator.timeRemaining(for: token, at: date)
        
        XCTAssertEqual(remaining, 1, "At end of period, should have 1 second remaining")
    }
    
    // MARK: - Code Formatting Tests
    
    func testFormat_6DigitCode_ReturnsFormattedWith3_3() {
        let formatted = TOTPGenerator.format(code: "123456")
        XCTAssertEqual(formatted, "123 456", "6-digit code should format as '123 456'")
    }
    
    func testFormat_8DigitCode_ReturnsFormattedWith4_4() {
        let formatted = TOTPGenerator.format(code: "12345678")
        XCTAssertEqual(formatted, "1234 5678", "8-digit code should format as '1234 5678'")
    }
    
    func testFormat_InvalidLength_ReturnsUnchanged() {
        let formatted = TOTPGenerator.format(code: "12345")
        XCTAssertEqual(formatted, "12345", "Invalid length should return unchanged")
    }
    
    // MARK: - Error Cases
    
    func testGenerate_InvalidSecret_ReturnsNil() {
        let token = Token(
            issuer: "Test",
            account: "test",
            secret: "INVALID!@#$",
            digits: 6,
            period: 30
        )
        
        let code = TOTPGenerator.generate(token: token)
        
        XCTAssertNil(code, "Invalid secret should return nil")
    }
    
    // MARK: - Consistency Tests
    
    func testGenerate_SameTime_ReturnsSameCode() {
        let token = Token(
            issuer: "Test",
            account: "test",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30
        )
        
        let date = Date(timeIntervalSince1970: 1234567890)
        let code1 = TOTPGenerator.generate(token: token, time: date)
        let code2 = TOTPGenerator.generate(token: token, time: date)
        
        XCTAssertEqual(code1, code2, "Same time should generate same code")
    }
    
    func testGenerate_DifferentTime_ReturnsDifferentCode() {
        let token = Token(
            issuer: "Test",
            account: "test",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30
        )
        
        let date1 = Date(timeIntervalSince1970: 1234567890)
        let date2 = Date(timeIntervalSince1970: 1234567890 + 30) // Next period
        
        let code1 = TOTPGenerator.generate(token: token, time: date1)
        let code2 = TOTPGenerator.generate(token: token, time: date2)
        
        XCTAssertNotEqual(code1, code2, "Different periods should generate different codes")
    }
    
    // MARK: - Performance Tests
    
    func testGeneratePerformance() {
        let token = Token(
            issuer: "Test",
            account: "test",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30
        )
        
        measure {
            for _ in 0..<1000 {
                _ = TOTPGenerator.generate(token: token)
            }
        }
        
        // Performance should be < 50ms per generation (requirement)
    }
}
