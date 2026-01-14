import XCTest
@testable import Second

/// Integration test for add first token flow
final class AddTokenIntegrationTests: XCTestCase {

    func testAddFirstTokenFlow() throws {
        // Given: Empty vault
        var vault = Vault()
        XCTAssertEqual(vault.tokens.count, 0)

        // When: Adding token
        let token = Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP"
        )
        vault.addToken(token)

        // Then: Token added
        XCTAssertEqual(vault.tokens.count, 1)
        XCTAssertEqual(vault.tokens.first?.issuer, "GitHub")
    }
}
