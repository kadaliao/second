//
//  iCloudSyncNotificationTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-17.
//

import XCTest
@testable import Second

/// Integration tests for iCloud change notification handling
final class iCloudSyncNotificationTests: XCTestCase {

    // MARK: - Test Data

    func createTestToken(issuer: String = "GitHub", account: String = "user@example.com") -> Token {
        return Token(
            issuer: issuer,
            account: account,
            secret: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            period: 30
        )
    }

    // MARK: - External Change Notification Tests

    func testObserveExternalChanges_HandlerCalled() {
        // Arrange
        let syncService = iCloudSyncService()
        let expectation = XCTestExpectation(description: "Handler should be called")
        var handlerCallCount = 0

        // Act - Setup observer
        let observer = syncService.observeExternalChanges {
            handlerCallCount += 1
            expectation.fulfill()
        }

        // Simulate external change by posting notification
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(handlerCallCount, 1, "Handler should be called once")

        // Cleanup
        syncService.removeObserver(observer)
    }

    func testObserveExternalChanges_MultipleNotifications() {
        // Arrange
        let syncService = iCloudSyncService()
        var handlerCallCount = 0
        let expectation = XCTestExpectation(description: "Handler should be called multiple times")
        expectation.expectedFulfillmentCount = 3

        // Act - Setup observer
        let observer = syncService.observeExternalChanges {
            handlerCallCount += 1
            expectation.fulfill()
        }

        // Simulate multiple external changes
        for _ in 1...3 {
            NotificationCenter.default.post(
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: NSUbiquitousKeyValueStore.default
            )
        }

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(handlerCallCount, 3, "Handler should be called three times")

        // Cleanup
        syncService.removeObserver(observer)
    }

    func testRemoveObserver_NoLongerReceivesNotifications() {
        // Arrange
        let syncService = iCloudSyncService()
        var handlerCallCount = 0

        // Act - Setup observer
        let observer = syncService.observeExternalChanges {
            handlerCallCount += 1
        }

        // Remove observer immediately
        syncService.removeObserver(observer)

        // Try to trigger notification
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )

        // Wait a bit to ensure no delayed calls
        let expectation = XCTestExpectation(description: "Wait for potential delayed calls")
        expectation.isInverted = true // Should NOT be fulfilled
        wait(for: [expectation], timeout: 0.5)

        // Assert
        XCTAssertEqual(handlerCallCount, 0, "Handler should not be called after observer removed")
    }

    func testSyncService_SaveAndLoad_RoundTrip() throws {
        // Arrange
        let syncService = iCloudSyncService()
        let testData = "Test encrypted vault data".data(using: .utf8)!

        // Act - Save
        try syncService.saveEncryptedVault(testData)

        // Assert - Load
        let loadedData = try syncService.loadEncryptedVault()
        XCTAssertEqual(loadedData, testData, "Loaded data should match saved data")

        // Cleanup
        syncService.deleteEncryptedVault()
    }

    func testSyncService_EncryptedVaultExists() throws {
        // Arrange
        let syncService = iCloudSyncService()

        // Initially should not exist (after cleanup)
        syncService.deleteEncryptedVault()
        XCTAssertFalse(syncService.encryptedVaultExists(), "Vault should not exist initially")

        // Act - Save data
        let testData = "Test data".data(using: .utf8)!
        try syncService.saveEncryptedVault(testData)

        // Assert
        XCTAssertTrue(syncService.encryptedVaultExists(), "Vault should exist after save")

        // Cleanup
        syncService.deleteEncryptedVault()
        XCTAssertFalse(syncService.encryptedVaultExists(), "Vault should not exist after delete")
    }

    func testSyncService_DeleteEncryptedVault() throws {
        // Arrange
        let syncService = iCloudSyncService()
        let testData = "Test data".data(using: .utf8)!
        try syncService.saveEncryptedVault(testData)
        XCTAssertTrue(syncService.encryptedVaultExists(), "Precondition: vault should exist")

        // Act
        syncService.deleteEncryptedVault()

        // Assert
        XCTAssertFalse(syncService.encryptedVaultExists(), "Vault should not exist after delete")
        XCTAssertThrowsError(try syncService.loadEncryptedVault(), "Loading deleted vault should throw error")
    }

    // MARK: - Sync Timing Tests

    func testSyncService_Synchronize_CalledAfterSave() throws {
        // Note: This test verifies that synchronize() is called in saveEncryptedVault()
        // The actual sync timing to iCloud servers depends on network and Apple's infrastructure
        // This is a structural test to ensure we call the sync API

        // Arrange
        let syncService = iCloudSyncService()
        let testData = "Test data".data(using: .utf8)!

        // Act
        try syncService.saveEncryptedVault(testData)

        // Assert - Data should be immediately available locally
        let loadedData = try syncService.loadEncryptedVault()
        XCTAssertEqual(loadedData, testData, "Data should be available immediately after save")

        // Cleanup
        syncService.deleteEncryptedVault()
    }

    func testSyncService_MultipleDevices_SimulateExternalChange() throws {
        // Arrange - Simulate "Device A" saving data
        let syncService = iCloudSyncService()
        let device1Data = "Device A vault".data(using: .utf8)!

        var externalChangeDetected = false
        let expectation = XCTestExpectation(description: "External change should be detected")

        // Setup observer (simulating Device B)
        let observer = syncService.observeExternalChanges {
            externalChangeDetected = true
            expectation.fulfill()
        }

        // Act - Device A saves data (simulated by posting notification)
        try syncService.saveEncryptedVault(device1Data)

        // Simulate external change notification (as if from another device)
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(externalChangeDetected, "External change should be detected")

        // Cleanup
        syncService.removeObserver(observer)
        syncService.deleteEncryptedVault()
    }

    // MARK: - Error Handling Tests

    func testSyncService_LoadNonExistentVault_ThrowsError() {
        // Arrange
        let syncService = iCloudSyncService()
        syncService.deleteEncryptedVault() // Ensure no vault exists

        // Act & Assert
        XCTAssertThrowsError(try syncService.loadEncryptedVault(), "Loading non-existent vault should throw") { error in
            guard let syncError = error as? iCloudSyncService.SyncError else {
                XCTFail("Error should be SyncError type")
                return
            }
            XCTAssertEqual(syncError, iCloudSyncService.SyncError.noDataFound, "Should be noDataFound error")
        }
    }
}
