//
//  QRCodeParserTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
@testable import Second

final class QRCodeParserTests: XCTestCase {
    
    // MARK: - Valid URI Tests
    
    func testParse_MinimalURI_ReturnsToken() throws {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "user@example.com")
        XCTAssertEqual(token.secret, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(token.digits, 6)
        XCTAssertEqual(token.period, 30)
        XCTAssertEqual(token.algorithm, .sha1)
    }
    
    func testParse_FullURI_ReturnsToken() throws {
        let uri = "otpauth://totp/Google:user@gmail.com?secret=GEZDGNBVGY3TQOJQ&issuer=Google&algorithm=SHA256&digits=8&period=60"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Google")
        XCTAssertEqual(token.account, "user@gmail.com")
        XCTAssertEqual(token.secret, "GEZDGNBVGY3TQOJQ")
        XCTAssertEqual(token.digits, 8)
        XCTAssertEqual(token.period, 60)
        XCTAssertEqual(token.algorithm, .sha256)
    }
    
    func testParse_NoIssuerInLabel_UsesQueryParameter() throws {
        let uri = "otpauth://totp/user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Amazon"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Amazon")
        XCTAssertEqual(token.account, "user@example.com")
    }
    
    func testParse_NoIssuerAnywhere_UsesDefault() throws {
        let uri = "otpauth://totp/user@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "未知")
        XCTAssertEqual(token.account, "user@example.com")
    }
    
    func testParse_SHA512Algorithm_ReturnsToken() throws {
        let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&algorithm=SHA512"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.algorithm, .sha512)
    }
    
    // MARK: - URL Encoding Tests
    
    func testParse_URLEncodedIssuer_Decodes() throws {
        let uri = "otpauth://totp/Google%20Workspace:admin@company.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Google Workspace")
        XCTAssertEqual(token.account, "admin@company.com")
    }
    
    func testParse_URLEncodedAccount_Decodes() throws {
        let uri = "otpauth://totp/GitHub:user%2Btest@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.account, "user+test@example.com")
    }
    
    func testParse_URLEncodedSpecialChars_Decodes() throws {
        let uri = "otpauth://totp/Test%20%26%20Co.:user@test.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Test & Co.")
    }
    
    // MARK: - Case Insensitivity Tests
    
    func testParse_LowercaseScheme_Works() throws {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "GitHub")
    }
    
    func testParse_UppercaseScheme_Works() throws {
        let uri = "OTPAUTH://TOTP/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "GitHub")
    }
    
    func testParse_MixedCaseAlgorithm_Works() throws {
        let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&algorithm=Sha256"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.algorithm, .sha256)
    }
    
    // MARK: - Error Cases - Invalid Scheme
    
    func testParse_InvalidScheme_ThrowsError() {
        let uri = "http://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidScheme = error else {
                XCTFail("Expected invalidScheme error")
                return
            }
        }
    }
    
    func testParse_NoScheme_ThrowsError() {
        let uri = "GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidScheme = error else {
                XCTFail("Expected invalidScheme error")
                return
            }
        }
    }
    
    // MARK: - Error Cases - Unsupported Type
    
    func testParse_HOTPType_ThrowsError() {
        let uri = "otpauth://hotp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.unsupportedType = error else {
                XCTFail("Expected unsupportedType error")
                return
            }
        }
    }
    
    // MARK: - Error Cases - Missing Secret
    
    func testParse_NoSecret_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.missingSecret = error else {
                XCTFail("Expected missingSecret error")
                return
            }
        }
    }
    
    func testParse_EmptySecret_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret="
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidSecret = error else {
                XCTFail("Expected invalidSecret error")
                return
            }
        }
    }
    
    // MARK: - Error Cases - Invalid Secret
    
    func testParse_InvalidBase32Secret_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=INVALID!@#$"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidSecret = error else {
                XCTFail("Expected invalidSecret error")
                return
            }
        }
    }
    
    func testParse_SecretWithInvalidChars_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=ABC123DEF"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidSecret = error else {
                XCTFail("Expected invalidSecret error")
                return
            }
        }
    }
    
    // MARK: - Error Cases - Invalid Algorithm
    
    func testParse_UnsupportedAlgorithm_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&algorithm=MD5"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.unsupportedAlgorithm = error else {
                XCTFail("Expected unsupportedAlgorithm error")
                return
            }
        }
    }
    
    // MARK: - Error Cases - Invalid Digits
    
    func testParse_InvalidDigits4_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&digits=4"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidDigits = error else {
                XCTFail("Expected invalidDigits error")
                return
            }
        }
    }
    
    func testParse_InvalidDigits10_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&digits=10"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidDigits = error else {
                XCTFail("Expected invalidDigits error")
                return
            }
        }
    }
    
    func testParse_NonNumericDigits_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&digits=abc"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidDigits = error else {
                XCTFail("Expected invalidDigits error")
                return
            }
        }
    }
    
    // MARK: - Error Cases - Invalid Period
    
    func testParse_NegativePeriod_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&period=-30"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidPeriod = error else {
                XCTFail("Expected invalidPeriod error")
                return
            }
        }
    }
    
    func testParse_ZeroPeriod_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&period=0"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidPeriod = error else {
                XCTFail("Expected invalidPeriod error")
                return
            }
        }
    }
    
    func testParse_NonNumericPeriod_ThrowsError() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&period=abc"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.invalidPeriod = error else {
                XCTFail("Expected invalidPeriod error")
                return
            }
        }
    }
    
    // MARK: - Real World Examples
    
    func testParse_GoogleExample_Works() throws {
        let uri = "otpauth://totp/Google%3Auser%40gmail.com?secret=GEZDGNBVGY3TQOJQ&issuer=Google"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Google")
        XCTAssertEqual(token.account, "user@gmail.com")
        XCTAssertEqual(token.secret, "GEZDGNBVGY3TQOJQ")
    }
    
    func testParse_GitHubExample_Works() throws {
        let uri = "otpauth://totp/GitHub:username?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "username")
    }
    
    func testParse_MicrosoftExample_Works() throws {
        let uri = "otpauth://totp/Microsoft:user@outlook.com?secret=JBSWY3DPEHPK3PXP&issuer=Microsoft&algorithm=SHA256&digits=8"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Microsoft")
        XCTAssertEqual(token.account, "user@outlook.com")
        XCTAssertEqual(token.digits, 8)
        XCTAssertEqual(token.algorithm, .sha256)
    }
    
    // MARK: - Edge Cases
    
    func testParse_EmptyIssuer_UsesQueryParameter() throws {
        let uri = "otpauth://totp/:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Service"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Service")
        XCTAssertEqual(token.account, "user@example.com")
    }
    
    func testParse_OnlyAccount_NoColonInLabel() throws {
        let uri = "otpauth://totp/user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Service"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Service")
        XCTAssertEqual(token.account, "user@example.com")
    }
    
    func testParse_MultipleColonsInLabel_UsesFirstAsSeparator() throws {
        let uri = "otpauth://totp/Service:user:name@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Service")
        XCTAssertEqual(token.account, "user:name@example.com")
    }
}
