import XCTest
@testable import Second

/// Unit tests for Base32 decoder using RFC 4648 test vectors
final class Base32DecoderTests: XCTestCase {

    func testDecodeRFC4648Vectors() throws {
        // RFC 4648 test vectors
        XCTAssertEqual(try Base32Decoder.decode(""), Data())
        XCTAssertEqual(try Base32Decoder.decode("MY======"), Data("f".utf8))
        XCTAssertEqual(try Base32Decoder.decode("MZXQ===="), Data("fo".utf8))
        XCTAssertEqual(try Base32Decoder.decode("MZXW6==="), Data("foo".utf8))
        XCTAssertEqual(try Base32Decoder.decode("MZXW6YQ="), Data("foob".utf8))
        XCTAssertEqual(try Base32Decoder.decode("MZXW6YTB"), Data("fooba".utf8))
        XCTAssertEqual(try Base32Decoder.decode("MZXW6YTBOI======"), Data("foobar".utf8))
    }

    func testDecodeWithoutPadding() throws {
        // Base32 without padding (common in TOTP)
        XCTAssertEqual(try Base32Decoder.decode("MZXW6YTB"), Data("fooba".utf8))
    }

    func testDecodeCaseInsensitive() throws {
        // Lowercase should work
        XCTAssertEqual(try Base32Decoder.decode("mzxw6ytb"), Data("fooba".utf8))
    }

    func testDecodeInvalidCharacter() {
        // Invalid characters should throw
        XCTAssertThrowsError(try Base32Decoder.decode("INVALID!@#"))
    }
}
