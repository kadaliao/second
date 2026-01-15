import XCTest
@testable import Second

/// Integration tests for iCloud KVStore mock operations
final class iCloudSyncTests: XCTestCase {

    func testSaveAndLoadVault() throws {
        // Given: Mock sync service
        let service = iCloudSyncService()
        let testData = "test vault".data(using: .utf8)!

        // When: Saving and loading
        try service.saveVault(testData)
        let loaded = try service.loadVault()

        // Then: Data matches
        XCTAssertEqual(loaded, testData)
    }

    func testLoadEmptyVaultReturnsNil() throws {
        // Given: Fresh service
        let service = iCloudSyncService()

        // Then: No vault returns nil
        XCTAssertNil(try service.loadVault())
    }
}
