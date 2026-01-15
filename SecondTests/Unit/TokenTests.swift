import XCTest
@testable import Second

/// Unit tests for Token validation
final class TokenTests: XCTestCase {

    func testTokenWithValidData() {
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        )

        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "user@example.com")
        XCTAssertEqual(token.digits, 6)
        XCTAssertEqual(token.period, 30)
    }

    func testTokenTrimsWhitespace() {
        let token = Token(
            issuer: "  GitHub  ",
            account: "  user@example.com  ",
            secret: "JBSWY3DPEHPK3PXP"
        )

        XCTAssertEqual(token.issuer, "GitHub")
        XCTAssertEqual(token.account, "user@example.com")
    }
}
