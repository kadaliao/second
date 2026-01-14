//
//  SyncConflictTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-17.
//

import XCTest
@testable import Second
import CryptoKit

/// Integration tests for sync conflict resolution (last-write-wins)
final class SyncConflictTests: XCTestCase {

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

    func createTestVault(tokens: [Token]) -> Vault {
        var vault = Vault()
        tokens.forEach { vault.addToken($0) }
        return vault
    }

    // MARK: - Last-Write-Wins Tests

    func testSyncConflict_LastWriteWins_VaultLastModified() throws {
        // Arrange - Two vaults with different lastModified times
        let token1 = createTestToken(issuer: "GitHub", account: "user1@example.com")
        let token2 = createTestToken(issuer: "Google", account: "user2@example.com")

        var vault1 = createTestVault(tokens: [token1])
        Thread.sleep(forTimeInterval: 0.01) // Ensure timestamp difference
        var vault2 = createTestVault(tokens: [token2])

        // Act - Simulate conflict: vault2 has later timestamp
        let winningVault = vault2.lastModified > vault1.lastModified ? vault2 : vault1

        // Assert
        XCTAssertEqual(winningVault.tokens.count, 1, "Winning vault should have its original tokens")
        XCTAssertEqual(winningVault.tokens[0].issuer, "Google", "Last write (vault2) should win")
        XCTAssertGreaterThan(vault2.lastModified, vault1.lastModified, "vault2 should have later timestamp")
    }

    func testSyncConflict_EncryptDecryptRoundTrip() throws {
        // Arrange
        let vault = createTestVault(tokens: [
            createTestToken(issuer: "GitHub"),
            createTestToken(issuer: "Google")
        ])
        let key = KeychainService.generateVaultKey()

        // Act - Encrypt and decrypt
        let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)
        let decryptedVault = try EncryptionService.decrypt(encryptedData: encryptedData, using: key)

        // Assert
        XCTAssertEqual(decryptedVault.tokens.count, vault.tokens.count, "Token count should match")
        XCTAssertEqual(decryptedVault.tokens[0].issuer, vault.tokens[0].issuer, "First token should match")
        XCTAssertEqual(decryptedVault.tokens[1].issuer, vault.tokens[1].issuer, "Second token should match")
        XCTAssertEqual(decryptedVault.version, vault.version, "Version should match")
    }

    func testSyncConflict_TwoDevices_LastModifiedWins() throws {
        // Arrange - Simulate two devices with conflicting changes
        let sharedKey = KeychainService.generateVaultKey()

        // Device A: Creates vault with token1
        var vaultA = Vault()
        let token1 = createTestToken(issuer: "GitHub", account: "deviceA@example.com")
        vaultA.addToken(token1)
        let encryptedA = try EncryptionService.encrypt(vault: vaultA, using: sharedKey)

        // Wait to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Device B: Creates vault with token2 (later timestamp)
        var vaultB = Vault()
        let token2 = createTestToken(issuer: "Google", account: "deviceB@example.com")
        vaultB.addToken(token2)
        let encryptedB = try EncryptionService.encrypt(vault: vaultB, using: sharedKey)

        // Act - Simulate iCloud resolving conflict
        // Last-write-wins: vaultB should win because it has later lastModified
        let decryptedA = try EncryptionService.decrypt(encryptedData: encryptedA, using: sharedKey)
        let decryptedB = try EncryptionService.decrypt(encryptedData: encryptedB, using: sharedKey)

        let winner = decryptedB.lastModified > decryptedA.lastModified ? decryptedB : decryptedA

        // Assert
        XCTAssertEqual(winner.tokens[0].issuer, "Google", "Device B's vault should win")
        XCTAssertGreaterThan(decryptedB.lastModified, decryptedA.lastModified, "Device B timestamp should be later")
    }

    func testSyncConflict_SimultaneousEdits_LastOneWins() throws {
        // Arrange - Two devices edit the same token simultaneously
        let sharedKey = KeychainService.generateVaultKey()
        let originalToken = createTestToken(issuer: "GitHub", account: "original@example.com")

        var vault = Vault()
        vault.addToken(originalToken)

        // Device A: Edits token to "GitLab"
        var vaultA = vault
        var editedTokenA = originalToken
        editedTokenA.issuer = "GitLab"
        vaultA.updateToken(editedTokenA)

        // Wait to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Device B: Edits same token to "Bitbucket" (later)
        var vaultB = vault
        var editedTokenB = originalToken
        editedTokenB.issuer = "Bitbucket"
        vaultB.updateToken(editedTokenB)

        // Act - Last-write-wins resolution
        let winner = vaultB.lastModified > vaultA.lastModified ? vaultB : vaultA

        // Assert
        XCTAssertEqual(winner.tokens[0].issuer, "Bitbucket", "Device B's edit should win")
        XCTAssertGreaterThan(vaultB.lastModified, vaultA.lastModified, "Device B should have later timestamp")
    }

    func testSyncConflict_VaultValidation_AfterMerge() throws {
        // Arrange
        var vault = Vault()
        let token1 = createTestToken(issuer: "GitHub")
        let token2 = createTestToken(issuer: "Google")
        vault.addToken(token1)
        vault.addToken(token2)

        // Act - Validate vault after merge
        XCTAssertNoThrow(try vault.validate(), "Vault should be valid after merge")

        // Assert - No duplicate IDs
        let ids = vault.tokens.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "Should have no duplicate token IDs")
    }

    func testSyncConflict_EmptyVault_Overwrites() throws {
        // Arrange
        let key = KeychainService.generateVaultKey()

        // Device A: Has tokens
        var vaultA = Vault()
        vaultA.addToken(createTestToken(issuer: "GitHub"))
        vaultA.addToken(createTestToken(issuer: "Google"))

        // Wait
        Thread.sleep(forTimeInterval: 0.01)

        // Device B: Empty vault (later timestamp - user deleted all tokens)
        let vaultB = Vault()

        // Act - Last-write-wins: empty vault should win
        let winner = vaultB.lastModified > vaultA.lastModified ? vaultB : vaultA

        // Assert
        XCTAssertTrue(winner.tokens.isEmpty, "Empty vault should win and overwrite")
        XCTAssertEqual(winner.tokens.count, 0, "All tokens should be deleted")
    }

    // MARK: - iCloud Sync Integration Tests

    func testSyncConflict_iCloudSync_LastWritePreserved() throws {
        // Arrange
        let syncService = iCloudSyncService()
        let key = KeychainService.generateVaultKey()

        // Device A writes first
        var vaultA = Vault()
        vaultA.addToken(createTestToken(issuer: "GitHub"))
        let encryptedA = try EncryptionService.encrypt(vault: vaultA, using: key)
        try syncService.saveEncryptedVault(encryptedA)

        // Wait
        Thread.sleep(forTimeInterval: 0.01)

        // Device B writes later (should overwrite)
        var vaultB = Vault()
        vaultB.addToken(createTestToken(issuer: "Google"))
        let encryptedB = try EncryptionService.encrypt(vault: vaultB, using: key)
        try syncService.saveEncryptedVault(encryptedB)

        // Act - Load from iCloud
        let loadedEncrypted = try syncService.loadEncryptedVault()
        let loadedVault = try EncryptionService.decrypt(encryptedData: loadedEncrypted, using: key)

        // Assert - Should have Device B's data (last write)
        XCTAssertEqual(loadedVault.tokens.count, 1, "Should have one token")
        XCTAssertEqual(loadedVault.tokens[0].issuer, "Google", "Should have Device B's token")

        // Cleanup
        syncService.deleteEncryptedVault()
    }

    func testSyncConflict_MultipleWrites_OnlyLastVisible() throws {
        // Arrange
        let syncService = iCloudSyncService()
        let key = KeychainService.generateVaultKey()

        // Multiple rapid writes
        let issuers = ["GitHub", "Google", "Amazon", "Microsoft", "Apple"]
        var lastVault: Vault?

        for issuer in issuers {
            var vault = Vault()
            vault.addToken(createTestToken(issuer: issuer))
            let encrypted = try EncryptionService.encrypt(vault: vault, using: key)
            try syncService.saveEncryptedVault(encrypted)
            lastVault = vault
            Thread.sleep(forTimeInterval: 0.005) // Small delay between writes
        }

        // Act - Load final state
        let loadedEncrypted = try syncService.loadEncryptedVault()
        let loadedVault = try EncryptionService.decrypt(encryptedData: loadedEncrypted, using: key)

        // Assert - Should have last write
        XCTAssertEqual(loadedVault.tokens.count, 1, "Should have one token")
        XCTAssertEqual(loadedVault.tokens[0].issuer, "Apple", "Should have last write")
        XCTAssertNotNil(lastVault, "Last vault should exist")

        // Cleanup
        syncService.deleteEncryptedVault()
    }
}
