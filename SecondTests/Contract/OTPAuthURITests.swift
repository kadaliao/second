//
//  OTPAuthURITests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
@testable import Second

/// Tests for otpauth:// URI format compliance
/// Based on Google Authenticator Key Uri Format specification
final class OTPAuthURITests: XCTestCase {
    
    // MARK: - URI Scheme Tests
    
    func testOTPAuthURI_Scheme_MustBeOtpauth() {
        let validURI = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        XCTAssertNoThrow(try QRCodeParser.parse(validURI))
        
        let invalidScheme = "http://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        XCTAssertThrowsError(try QRCodeParser.parse(invalidScheme))
    }
    
    func testOTPAuthURI_Scheme_CaseInsensitive() throws {
        let lowercaseURI = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        let uppercaseURI = "OTPAUTH://TOTP/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        let mixedcaseURI = "OtPaUtH://ToTp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        
        XCTAssertNoThrow(try QRCodeParser.parse(lowercaseURI))
        XCTAssertNoThrow(try QRCodeParser.parse(uppercaseURI))
        XCTAssertNoThrow(try QRCodeParser.parse(mixedcaseURI))
    }
    
    // MARK: - Type Tests
    
    func testOTPAuthURI_Type_MustBeTOTP() throws {
        let totpURI = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        XCTAssertNoThrow(try QRCodeParser.parse(totpURI))
        
        let hotpURI = "otpauth://hotp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        XCTAssertThrowsError(try QRCodeParser.parse(hotpURI)) { error in
            guard case QRCodeParser.ParseError.unsupportedType = error else {
                XCTFail("Expected unsupportedType error")
                return
            }
        }
    }
    
    // MARK: - Label Format Tests
    
    func testOTPAuthURI_Label_IssuerColonAccount() throws {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "user@example.com")
    }
    
    func testOTPAuthURI_Label_AccountOnly() throws {
        let uri = "otpauth://totp/user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "user@example.com")
    }
    
    func testOTPAuthURI_Label_URLEncoded() throws {
        let uri = "otpauth://totp/Google%20Workspace:admin%40company.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Google Workspace")
        XCTAssertEqual(token.account, "admin@company.com")
    }
    
    func testOTPAuthURI_Label_SpecialCharactersEncoded() throws {
        let uri = "otpauth://totp/Test%20%26%20Co.:user@test.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Test & Co.")
    }
    
    // MARK: - Secret Parameter Tests
    
    func testOTPAuthURI_Secret_Required() {
        let uriWithoutSecret = "otpauth://totp/Test:test@test.com"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uriWithoutSecret)) { error in
            guard case QRCodeParser.ParseError.missingSecret = error else {
                XCTFail("Expected missingSecret error")
                return
            }
        }
    }
    
    func testOTPAuthURI_Secret_MustBeBase32() throws {
        let validSecret = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        XCTAssertNoThrow(try QRCodeParser.parse(validSecret))
        
        let invalidSecret = "otpauth://totp/Test:test@test.com?secret=INVALID!@#$"
        XCTAssertThrowsError(try QRCodeParser.parse(invalidSecret))
    }
    
    func testOTPAuthURI_Secret_CaseInsensitive() throws {
        let lowercaseURI = "otpauth://totp/Test:test@test.com?secret=jbswy3dpehpk3pxp"
        let uppercaseURI = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        
        let token1 = try QRCodeParser.parse(lowercaseURI)
        let token2 = try QRCodeParser.parse(uppercaseURI)
        
        // Should both be normalized to uppercase
        XCTAssertEqual(token1.secret.uppercased(), token2.secret.uppercased())
    }
    
    // MARK: - Algorithm Parameter Tests
    
    func testOTPAuthURI_Algorithm_DefaultSHA1() throws {
        let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.algorithm, .sha1, "Default algorithm should be SHA1")
    }
    
    func testOTPAuthURI_Algorithm_SHA256() throws {
        let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.algorithm, .sha256)
    }
    
    func testOTPAuthURI_Algorithm_SHA512() throws {
        let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&algorithm=SHA512"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.algorithm, .sha512)
    }
    
    func testOTPAuthURI_Algorithm_CaseInsensitive() throws {
        let uris = [
            "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&algorithm=sha256",
            "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256",
            "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&algorithm=Sha256"
        ]
        
        for uri in uris {
            let token = try QRCodeParser.parse(uri)
            XCTAssertEqual(token.algorithm, .sha256)
        }
    }
    
    func testOTPAuthURI_Algorithm_UnsupportedValue() {
        let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&algorithm=MD5"
        
        XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
            guard case QRCodeParser.ParseError.unsupportedAlgorithm = error else {
                XCTFail("Expected unsupportedAlgorithm error")
                return
            }
        }
    }
    
    // MARK: - Digits Parameter Tests
    
    func testOTPAuthURI_Digits_Default6() throws {
        let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.digits, 6, "Default digits should be 6")
    }
    
    func testOTPAuthURI_Digits_ValidValues() throws {
        for digits in [6, 7, 8] {
            let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&digits=\(digits)"
            let token = try QRCodeParser.parse(uri)
            
            XCTAssertEqual(token.digits, digits)
        }
    }
    
    func testOTPAuthURI_Digits_InvalidValues() {
        let invalidDigits = [4, 5, 9, 10]
        
        for digits in invalidDigits {
            let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&digits=\(digits)"
            
            XCTAssertThrowsError(try QRCodeParser.parse(uri)) { error in
                guard case QRCodeParser.ParseError.invalidDigits = error else {
                    XCTFail("Expected invalidDigits error for digits=\(digits)")
                    return
                }
            }
        }
    }
    
    // MARK: - Period Parameter Tests
    
    func testOTPAuthURI_Period_Default30() throws {
        let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.period, 30, "Default period should be 30")
    }
    
    func testOTPAuthURI_Period_CustomValue() throws {
        let uri = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&period=60"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.period, 60)
    }
    
    func testOTPAuthURI_Period_MustBePositive() {
        let negativePeriod = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&period=-30"
        let zeroPeriod = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&period=0"
        
        XCTAssertThrowsError(try QRCodeParser.parse(negativePeriod))
        XCTAssertThrowsError(try QRCodeParser.parse(zeroPeriod))
    }
    
    // MARK: - Issuer Parameter Tests
    
    func testOTPAuthURI_Issuer_InLabel() throws {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "GitHub")
    }
    
    func testOTPAuthURI_Issuer_InQueryParameter() throws {
        let uri = "otpauth://totp/user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "GitHub")
    }
    
    func testOTPAuthURI_Issuer_QueryParameterOverridesLabel() throws {
        let uri = "otpauth://totp/WrongIssuer:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=CorrectIssuer"
        let token = try QRCodeParser.parse(uri)
        
        // Label issuer takes precedence if both exist
        XCTAssertEqual(token.issuer, "WrongIssuer")
    }
    
    func testOTPAuthURI_Issuer_DefaultValue() throws {
        let uri = "otpauth://totp/user@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "未知", "Should use default issuer when not specified")
    }
    
    // MARK: - Real World Examples Compliance
    
    func testOTPAuthURI_GoogleAuthenticatorFormat() throws {
        let uri = "otpauth://totp/Google%3Auser%40gmail.com?secret=GEZDGNBVGY3TQOJQ&issuer=Google"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Google")
        XCTAssertEqual(token.account, "user@gmail.com")
        XCTAssertEqual(token.secret, "GEZDGNBVGY3TQOJQ")
        XCTAssertEqual(token.digits, 6)
        XCTAssertEqual(token.period, 30)
        XCTAssertEqual(token.algorithm, .sha1)
    }
    
    func testOTPAuthURI_GitHubFormat() throws {
        let uri = "otpauth://totp/GitHub:username?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "username")
    }
    
    func testOTPAuthURI_MicrosoftFormat() throws {
        let uri = "otpauth://totp/Microsoft:user@outlook.com?secret=JBSWY3DPEHPK3PXP&issuer=Microsoft&algorithm=SHA256&digits=8"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Microsoft")
        XCTAssertEqual(token.account, "user@outlook.com")
        XCTAssertEqual(token.algorithm, .sha256)
        XCTAssertEqual(token.digits, 8)
    }
    
    // MARK: - URI Encoding Tests
    
    func testOTPAuthURI_SpecialCharacters_Encoded() throws {
        let encodedCharacters = [
            ("Space", "%20", " "),
            ("At", "%40", "@"),
            ("Colon", "%3A", ":"),
            ("Ampersand", "%26", "&"),
            ("Plus", "%2B", "+")
        ]
        
        for (_, encoded, decoded) in encodedCharacters {
            let uri = "otpauth://totp/Test\(encoded)Issuer:user@test.com?secret=JBSWY3DPEHPK3PXP"
            let token = try QRCodeParser.parse(uri)
            
            XCTAssertTrue(token.issuer.contains(decoded), "Should decode \(encoded) to \(decoded)")
        }
    }
    
    // MARK: - Edge Cases
    
    func testOTPAuthURI_MultipleColonsInLabel() throws {
        let uri = "otpauth://totp/Service:user:name@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Service")
        XCTAssertEqual(token.account, "user:name@example.com")
    }
    
    func testOTPAuthURI_EmptyIssuer() throws {
        let uri = "otpauth://totp/:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Service"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "Service")
        XCTAssertEqual(token.account, "user@example.com")
    }
    
    func testOTPAuthURI_QueryParameterOrder_Irrelevant() throws {
        let uri1 = "otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256&digits=8"
        let uri2 = "otpauth://totp/Test:test@test.com?digits=8&algorithm=SHA256&secret=JBSWY3DPEHPK3PXP"
        
        let token1 = try QRCodeParser.parse(uri1)
        let token2 = try QRCodeParser.parse(uri2)
        
        XCTAssertEqual(token1.issuer, token2.issuer)
        XCTAssertEqual(token1.secret, token2.secret)
        XCTAssertEqual(token1.digits, token2.digits)
        XCTAssertEqual(token1.algorithm, token2.algorithm)
    }
    
    // MARK: - Specification Compliance Tests
    
    func testOTPAuthURI_MinimalCompliantURI() throws {
        // Minimal URI according to spec: scheme + type + label + secret
        let uri = "otpauth://totp/account?secret=JBSWY3DPEHPK3PXP"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.account, "account")
        XCTAssertEqual(token.secret, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(token.digits, 6)
        XCTAssertEqual(token.period, 30)
        XCTAssertEqual(token.algorithm, .sha1)
    }
    
    func testOTPAuthURI_FullySpecifiedURI() throws {
        let uri = "otpauth://totp/TestIssuer:test@test.com?secret=JBSWY3DPEHPK3PXP&issuer=TestIssuer&algorithm=SHA256&digits=8&period=60"
        let token = try QRCodeParser.parse(uri)
        
        XCTAssertEqual(token.issuer, "TestIssuer")
        XCTAssertEqual(token.account, "test@test.com")
        XCTAssertEqual(token.secret, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(token.algorithm, .sha256)
        XCTAssertEqual(token.digits, 8)
        XCTAssertEqual(token.period, 60)
    }
    
    // MARK: - Invalid URI Tests
    
    func testOTPAuthURI_InvalidFormat_ThrowsError() {
        let invalidURIs = [
            "not-a-uri",
            "otpauth://",
            "otpauth://totp/",
            "totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP"
        ]
        
        for uri in invalidURIs {
            XCTAssertThrowsError(try QRCodeParser.parse(uri), "Should reject invalid URI: \(uri)")
        }
    }
}
