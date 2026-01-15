import XCTest
@testable import Second

/// Contract tests for otpauth:// URI parsing
/// Validates parsing matches contracts/otpauth-uri-spec.md
final class OTPAuthURITests: XCTestCase {

    func testParseMinimalURI() throws {
        // Given: Minimal valid URI
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"

        // When: Parsing
        let token = try OTPAuthURI.parse(uri)

        // Then: Defaults applied
        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "user@example.com")
        XCTAssertEqual(token.secret, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(token.digits, 6)
        XCTAssertEqual(token.period, 30)
        XCTAssertEqual(token.algorithm, .sha1)
    }

    func testParseFullURI() throws {
        // Given: URI with all parameters
        let uri = "otpauth://totp/Google:user@gmail.com?secret=GEZDGNBVGY3TQOJQ&issuer=Google&algorithm=SHA256&digits=8&period=60"

        // When: Parsing
        let token = try OTPAuthURI.parse(uri)

        // Then: All parameters parsed
        XCTAssertEqual(token.issuer, "Google")
        XCTAssertEqual(token.algorithm, .sha256)
        XCTAssertEqual(token.digits, 8)
        XCTAssertEqual(token.period, 60)
    }

    func testParseInvalidScheme() {
        // Given: Invalid scheme
        let uri = "http://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"

        // Then: Throws error
        XCTAssertThrowsError(try OTPAuthURI.parse(uri))
    }

    func testParseMissingSecret() {
        // Given: Missing secret
        let uri = "otpauth://totp/GitHub:user@example.com"

        // Then: Throws error
        XCTAssertThrowsError(try OTPAuthURI.parse(uri))
    }
}
