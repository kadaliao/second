import XCTest
import CryptoKit
@testable import Second

/// Unit tests for TOTP generation using RFC 6238 test vectors
final class TOTPGeneratorTests: XCTestCase {

    func testTOTPWithSHA1() throws {
        // Given: RFC 6238 test vector
        let generator = TOTPGenerator()
        let time = Date(timeIntervalSince1970: 59)

        // When: Generating TOTP
        let code = try generator.generate(
            secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
            date: time,
            digits: 8,
            period: 30,
            algorithm: .sha1
        )

        // Then: Matches RFC 6238 Appendix B
        XCTAssertEqual(code, "94287082")
    }

    func testTOTPWithSHA256() throws {
        // Given: SHA256 parameters
        let generator = TOTPGenerator()
        let time = Date(timeIntervalSince1970: 59)

        // When: Generating
        let code = try generator.generate(
            secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
            date: time,
            digits: 6,
            period: 30,
            algorithm: .sha256
        )

        // Then: 6 digits
        XCTAssertEqual(code.count, 6)
        XCTAssertTrue(code.allSatisfy { $0.isNumber })
    }

    func testTOTPRefreshesEvery30Seconds() throws {
        // Given: 30s period parameters
        let generator = TOTPGenerator()

        // When: Generating at different times
        let code1 = try generator.generate(
            secret: "JBSWY3DPEHPK3PXP",
            date: Date(timeIntervalSince1970: 30),
            digits: 6,
            period: 30,
            algorithm: .sha1
        )
        let code2 = try generator.generate(
            secret: "JBSWY3DPEHPK3PXP",
            date: Date(timeIntervalSince1970: 59),
            digits: 6,
            period: 30,
            algorithm: .sha1
        )
        let code3 = try generator.generate(
            secret: "JBSWY3DPEHPK3PXP",
            date: Date(timeIntervalSince1970: 60),
            digits: 6,
            period: 30,
            algorithm: .sha1
        )

        // Then: Same period = same code, different period = different code
        XCTAssertEqual(code1, code2)
        XCTAssertNotEqual(code2, code3)
    }
}
