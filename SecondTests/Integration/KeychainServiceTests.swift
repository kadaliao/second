import XCTest
@testable import Second

/// Integration tests for Keychain save/load operations
final class KeychainServiceTests: XCTestCase {

    let service = KeychainService()
    let testIdentifier = "test-vault-key"

    override func tearDown() {
        // Clean up test data
        try? service.deleteKey(identifier: testIdentifier)
        super.tearDown()
    }

    func testSaveAndLoadKey() throws {
        // Given: A symmetric key
        let key = SymmetricKey(size: .bits256)

        // When: Saving and loading
        try service.saveKey(key, identifier: testIdentifier)
        let loaded = try service.loadKey(identifier: testIdentifier)

        // Then: Keys match
        XCTAssertEqual(key.withUnsafeBytes { Data($0) },
                       loaded.withUnsafeBytes { Data($0) })
    }

    func testLoadNonexistentKeyThrows() {
        // Then: Loading missing key throws
        XCTAssertThrowsError(try service.loadKey(identifier: "nonexistent"))
    }
}
