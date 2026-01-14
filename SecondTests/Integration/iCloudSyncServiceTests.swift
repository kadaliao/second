//
//  iCloudSyncServiceTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
import CryptoKit
@testable import Second

final class iCloudSyncServiceTests: XCTestCase {

    var syncService: iCloudSyncService!

    override func setUp() {
        super.setUp()
        syncService = iCloudSyncService()
        // Clean up any existing data
        syncService.deleteEncryptedVault()
    }

    override func tearDown() {
        // Clean up after tests
        syncService.deleteEncryptedVault()
        syncService = nil
        super.tearDown()
    }

    // MARK: - Save Tests

    func testSaveEncryptedVault_SuccessfullySaves() {
        let testData = Data([0x01, 0x02, 0x03, 0x04])

        XCTAssertNoThrow(try syncService.saveEncryptedVault(testData))
    }

    func testSaveEncryptedVault_EmptyData_Saves() {
        let emptyData = Data()

        XCTAssertNoThrow(try syncService.saveEncryptedVault(emptyData))
    }

    func testSaveEncryptedVault_LargeData_Saves() {
        // iCloud KVS has 1MB limit, test with 100KB
        let largeData = Data(repeating: 0xFF, count: 100_000)

        XCTAssertNoThrow(try syncService.saveEncryptedVault(largeData))
    }

    // MARK: - Load Tests

    func testLoadEncryptedVault_NoDataSaved_ThrowsError() {
        XCTAssertThrowsError(try syncService.loadEncryptedVault()) { error in
            guard case iCloudSyncService.SyncError.noDataFound = error else {
                XCTFail("Expected noDataFound error")
                return
            }
        }
    }

    func testLoadEncryptedVault_AfterSave_ReturnsCorrectData() throws {
        let testData = Data([0x01, 0x02, 0x03, 0x04, 0x05])

        try syncService.saveEncryptedVault(testData)
        let loadedData = try syncService.loadEncryptedVault()

        XCTAssertEqual(loadedData, testData, "Loaded data should match saved data")
    }

    // MARK: - Exists Tests

    func testEncryptedVaultExists_NoData_ReturnsFalse() {
        XCTAssertFalse(syncService.encryptedVaultExists())
    }

    func testEncryptedVaultExists_AfterSave_ReturnsTrue() throws {
        let testData = Data([0x01, 0x02, 0x03])
        try syncService.saveEncryptedVault(testData)

        XCTAssertTrue(syncService.encryptedVaultExists())
    }

    func testEncryptedVaultExists_AfterDelete_ReturnsFalse() throws {
        let testData = Data([0x01, 0x02, 0x03])
        try syncService.saveEncryptedVault(testData)

        syncService.deleteEncryptedVault()

        XCTAssertFalse(syncService.encryptedVaultExists())
    }

    // MARK: - Delete Tests

    func testDeleteEncryptedVault_ExistingData_Deletes() throws {
        let testData = Data([0x01, 0x02, 0x03])
        try syncService.saveEncryptedVault(testData)

        syncService.deleteEncryptedVault()

        XCTAssertFalse(syncService.encryptedVaultExists())
        XCTAssertThrowsError(try syncService.loadEncryptedVault())
    }

    func testDeleteEncryptedVault_NoData_DoesNotThrow() {
        // Should not throw even if no data exists
        XCTAssertNoThrow(syncService.deleteEncryptedVault())
    }

    // MARK: - Overwrite Tests

    func testSaveEncryptedVault_Overwrite_ReplacesData() throws {
        let data1 = Data([0x01, 0x02, 0x03])
        let data2 = Data([0x0A, 0x0B, 0x0C, 0x0D])

        try syncService.saveEncryptedVault(data1)
        try syncService.saveEncryptedVault(data2)

        let loadedData = try syncService.loadEncryptedVault()

        XCTAssertEqual(loadedData, data2, "Second save should overwrite first")
        XCTAssertNotEqual(loadedData, data1)
    }

    // MARK: - Round Trip Tests

    func testRoundTrip_SaveAndLoad_PreservesData() throws {
        let originalData = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])

        try syncService.saveEncryptedVault(originalData)
        let loadedData = try syncService.loadEncryptedVault()

        XCTAssertEqual(loadedData, originalData)
    }

    func testRoundTrip_SaveDeleteSaveAgain_Works() throws {
        let data1 = Data([0x01, 0x02, 0x03])
        try syncService.saveEncryptedVault(data1)

        syncService.deleteEncryptedVault()

        let data2 = Data([0x0A, 0x0B, 0x0C])
        try syncService.saveEncryptedVault(data2)

        let loadedData = try syncService.loadEncryptedVault()
        XCTAssertEqual(loadedData, data2)
    }

    // MARK: - Integration with Encryption Tests

    func testIntegration_SaveEncryptedVault_Works() throws {
        let key = KeychainService.generateVaultKey()
        let vault = Vault(tokens: [
            Token(issuer: "GitHub", account: "user@example.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "GEZDGNBVGY3TQOJQ")
        ])

        // Encrypt vault
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)

        // Save to iCloud
        try syncService.saveEncryptedVault(encryptedData)

        // Load from iCloud
        let loadedData = try syncService.loadEncryptedVault()

        // Decrypt
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: key)

        XCTAssertEqual(decryptedVault.tokens.count, 2)
        XCTAssertEqual(decryptedVault.tokens[0].issuer, "GitHub")
        XCTAssertEqual(decryptedVault.tokens[1].issuer, "Google")
    }

    func testIntegration_FullWorkflow_EncryptSaveLoadDecrypt() throws {
        // 1. Generate key and save to Keychain
        let key = KeychainService.generateVaultKey()
        try KeychainService.saveVaultKey(key)

        // 2. Create vault
        let originalVault = Vault(tokens: [
            Token(issuer: "Test1", account: "test1@test.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Test2", account: "test2@test.com", secret: "GEZDGNBVGY3TQOJQ")
        ])

        // 3. Encrypt vault
        let encryptedData = try EncryptionService.encrypt(vault: originalVault, using: key)

        // 4. Save to iCloud
        try syncService.saveEncryptedVault(encryptedData)

        // 5. Verify exists
        XCTAssertTrue(syncService.encryptedVaultExists())

        // 6. Load from iCloud
        let loadedData = try syncService.loadEncryptedVault()

        // 7. Load key from Keychain
        let loadedKey = try KeychainService.loadVaultKey()

        // 8. Decrypt vault
        let decryptedVault = try EncryptionService.decrypt(encryptedData: loadedData, using: loadedKey)

        // 9. Verify data
        XCTAssertEqual(decryptedVault.tokens.count, 2)
        XCTAssertEqual(decryptedVault.tokens[0].issuer, "Test1")
        XCTAssertEqual(decryptedVault.tokens[1].issuer, "Test2")

        // Cleanup
        try KeychainService.deleteVaultKey()
    }

    // MARK: - Observer Tests

    func testObserveExternalChanges_ReturnsObserver() {
        let observer = syncService.observeExternalChanges {
            // Handler
        }

        XCTAssertNotNil(observer, "Should return valid observer")

        syncService.removeObserver(observer)
    }

    func testRemoveObserver_DoesNotCrash() {
        let observer = syncService.observeExternalChanges {
            // Handler
        }

        XCTAssertNoThrow(syncService.removeObserver(observer))
    }

    func testObserveExternalChanges_MultipleObservers_Work() {
        let observer1 = syncService.observeExternalChanges {
            // Handler 1
        }

        let observer2 = syncService.observeExternalChanges {
            // Handler 2
        }

        XCTAssertNotNil(observer1)
        XCTAssertNotNil(observer2)

        syncService.removeObserver(observer1)
        syncService.removeObserver(observer2)
    }

    // MARK: - Data Integrity Tests

    func testRoundTrip_BinaryData_PreservesAllBytes() throws {
        // Create data with all possible byte values
        let originalData = Data((0...255).map { UInt8($0) })

        try syncService.saveEncryptedVault(originalData)
        let loadedData = try syncService.loadEncryptedVault()

        XCTAssertEqual(loadedData.count, originalData.count)
        XCTAssertEqual(loadedData, originalData, "All bytes should be preserved")
    }

    func testRoundTrip_RandomData_PreservesData() throws {
        // Generate random data
        let originalData = Data((0..<1000).map { _ in UInt8.random(in: 0...255) })

        try syncService.saveEncryptedVault(originalData)
        let loadedData = try syncService.loadEncryptedVault()

        XCTAssertEqual(loadedData, originalData)
    }

    // MARK: - Edge Cases

    func testSaveEncryptedVault_SingleByte_Works() throws {
        let singleByte = Data([0x42])

        try syncService.saveEncryptedVault(singleByte)
        let loadedData = try syncService.loadEncryptedVault()

        XCTAssertEqual(loadedData, singleByte)
    }

    func testSaveEncryptedVault_MultipleSavesInSequence_LastWins() throws {
        let data1 = Data([0x01])
        let data2 = Data([0x02])
        let data3 = Data([0x03])

        try syncService.saveEncryptedVault(data1)
        try syncService.saveEncryptedVault(data2)
        try syncService.saveEncryptedVault(data3)

        let loadedData = try syncService.loadEncryptedVault()
        XCTAssertEqual(loadedData, data3, "Last save should win")
    }
}
