//
//  Base32DecoderTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
@testable import Second

final class Base32DecoderTests: XCTestCase {
    
    // MARK: - RFC 4648 Test Vectors
    
    func testDecode_EmptyString_ReturnsEmptyData() throws {
        let result = try Base32Decoder.decode("")
        XCTAssertEqual(result.count, 0, "Empty string should decode to empty data")
    }
    
    func testDecode_SingleCharacter_ReturnsCorrectData() throws {
        // "MY======" -> "f" (0x66)
        let result = try Base32Decoder.decode("MY")
        XCTAssertEqual(result, Data([0x66]), "MY should decode to 'f'")
    }
    
    func testDecode_TwoCharacters_ReturnsCorrectData() throws {
        // "MZXQ====" -> "fo" (0x66, 0x6F)
        let result = try Base32Decoder.decode("MZXQ")
        XCTAssertEqual(result, Data([0x66, 0x6F]), "MZXQ should decode to 'fo'")
    }
    
    func testDecode_ThreeCharacters_ReturnsCorrectData() throws {
        // "MZXW6===" -> "foo" (0x66, 0x6F, 0x6F)
        let result = try Base32Decoder.decode("MZXW6")
        XCTAssertEqual(result, Data([0x66, 0x6F, 0x6F]), "MZXW6 should decode to 'foo'")
    }
    
    func testDecode_FourCharacters_ReturnsCorrectData() throws {
        // "MZXW6YQ=" -> "foob" (0x66, 0x6F, 0x6F, 0x62)
        let result = try Base32Decoder.decode("MZXW6YQ")
        XCTAssertEqual(result, Data([0x66, 0x6F, 0x6F, 0x62]), "MZXW6YQ should decode to 'foob'")
    }
    
    func testDecode_FiveCharacters_ReturnsCorrectData() throws {
        // "MZXW6YTB" -> "fooba" (0x66, 0x6F, 0x6F, 0x62, 0x61)
        let result = try Base32Decoder.decode("MZXW6YTB")
        XCTAssertEqual(result, Data([0x66, 0x6F, 0x6F, 0x62, 0x61]), "MZXW6YTB should decode to 'fooba'")
    }
    
    func testDecode_SixCharacters_ReturnsCorrectData() throws {
        // "MZXW6YTBOI======" -> "foobar"
        let result = try Base32Decoder.decode("MZXW6YTBOI")
        XCTAssertEqual(result, Data([0x66, 0x6F, 0x6F, 0x62, 0x61, 0x72]), "MZXW6YTBOI should decode to 'foobar'")
    }
    
    // MARK: - Padding Tests
    
    func testDecode_WithPadding_ReturnsCorrectData() throws {
        let result = try Base32Decoder.decode("MZXW6===")
        XCTAssertEqual(result, Data([0x66, 0x6F, 0x6F]), "Padding should be ignored")
    }
    
    func testDecode_WithoutPadding_ReturnsCorrectData() throws {
        let result = try Base32Decoder.decode("MZXW6")
        XCTAssertEqual(result, Data([0x66, 0x6F, 0x6F]), "Should work without padding")
    }
    
    // MARK: - Case Sensitivity Tests
    
    func testDecode_Lowercase_ReturnsCorrectData() throws {
        let result = try Base32Decoder.decode("mzxw6ytboi")
        XCTAssertEqual(result, Data([0x66, 0x6F, 0x6F, 0x62, 0x61, 0x72]), "Lowercase should work")
    }
    
    func testDecode_MixedCase_ReturnsCorrectData() throws {
        let result = try Base32Decoder.decode("MzXw6YtBoI")
        XCTAssertEqual(result, Data([0x66, 0x6F, 0x6F, 0x62, 0x61, 0x72]), "Mixed case should work")
    }
    
    // MARK: - TOTP Secret Tests
    
    func testDecode_TOTPSecret_ReturnsCorrectData() throws {
        // Common TOTP test secret
        let result = try Base32Decoder.decode("JBSWY3DPEHPK3PXP")
        XCTAssertEqual(result.count, 10, "Should decode to 10 bytes")
        XCTAssertEqual(result, Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x21, 0xDE, 0xAD, 0xBE, 0xEF]))
    }
    
    func testDecode_GoogleAuthenticatorExample_ReturnsCorrectData() throws {
        // RFC 6238 test secret (Base32 encoded "12345678901234567890")
        let result = try Base32Decoder.decode("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ")
        XCTAssertEqual(result.count, 20, "Should decode to 20 bytes")
    }
    
    // MARK: - Whitespace Tests
    
    func testDecode_WithSpaces_ReturnsCorrectData() throws {
        let result = try Base32Decoder.decode("MZXW 6YTB OI")
        XCTAssertEqual(result, Data([0x66, 0x6F, 0x6F, 0x62, 0x61, 0x72]), "Spaces should be removed")
    }
    
    // MARK: - Error Cases
    
    func testDecode_InvalidCharacter_ThrowsError() {
        XCTAssertThrowsError(try Base32Decoder.decode("INVALID!@#$")) { error in
            guard case Base32Decoder.DecodingError.invalidCharacter = error else {
                XCTFail("Expected invalidCharacter error")
                return
            }
        }
    }
    
    func testDecode_InvalidCharacter_Number0_ThrowsError() {
        // '0' is not in Base32 alphabet (uses '2'-'7', not '0'-'9')
        XCTAssertThrowsError(try Base32Decoder.decode("INVALID0")) { error in
            guard case Base32Decoder.DecodingError.invalidCharacter = error else {
                XCTFail("Expected invalidCharacter error")
                return
            }
        }
    }
    
    func testDecode_InvalidCharacter_Number1_ThrowsError() {
        // '1' is not in Base32 alphabet
        XCTAssertThrowsError(try Base32Decoder.decode("INVALID1")) { error in
            guard case Base32Decoder.DecodingError.invalidCharacter = error else {
                XCTFail("Expected invalidCharacter error")
                return
            }
        }
    }
    
    // MARK: - Validation Tests
    
    func testIsValid_ValidString_ReturnsTrue() {
        XCTAssertTrue(Base32Decoder.isValid("MZXW6YTBOI"), "Valid Base32 should return true")
    }
    
    func testIsValid_ValidWithPadding_ReturnsTrue() {
        XCTAssertTrue(Base32Decoder.isValid("MZXW6==="), "Valid Base32 with padding should return true")
    }
    
    func testIsValid_Lowercase_ReturnsTrue() {
        XCTAssertTrue(Base32Decoder.isValid("mzxw6ytboi"), "Lowercase should be valid")
    }
    
    func testIsValid_InvalidCharacter_ReturnsFalse() {
        XCTAssertFalse(Base32Decoder.isValid("INVALID!"), "Invalid characters should return false")
    }
    
    func testIsValid_EmptyString_ReturnsFalse() {
        XCTAssertFalse(Base32Decoder.isValid(""), "Empty string should return false")
    }
    
    func testIsValid_WithSpaces_ReturnsTrue() {
        XCTAssertTrue(Base32Decoder.isValid("MZXW 6YTB"), "Spaces should be allowed")
    }
    
    // MARK: - Performance Tests
    
    func testDecodePerformance() {
        let longSecret = String(repeating: "MZXW6YTBOI", count: 10)
        
        measure {
            for _ in 0..<1000 {
                _ = try? Base32Decoder.decode(longSecret)
            }
        }
    }
}
