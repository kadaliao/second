import XCTest
@testable import Second

/// Unit tests for QRCodeParser with valid/invalid otpauth:// URIs
final class QRCodeParserTests: XCTestCase {

    func testParseValidMinimalURI() throws {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        let token = try OTPAuthURI.parse(uri)

        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "user@example.com")
        XCTAssertEqual(token.secret, "JBSWY3DPEHPK3PXP")
    }

    func testParseInvalidScheme() {
        let uri = "http://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        XCTAssertThrowsError(try OTPAuthURI.parse(uri))
    }

    func testParseMissingSecret() {
        let uri = "otpauth://totp/GitHub:user@example.com"
        XCTAssertThrowsError(try OTPAuthURI.parse(uri))
    }

    func testParseInvalidBase32Secret() {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=INVALID!@#"
        XCTAssertThrowsError(try OTPAuthURI.parse(uri))
    }
}
