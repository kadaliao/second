//
//  EditTokenIntegrationTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-17.
//

import XCTest
@testable import Second

/// Integration tests for edit token flow (edit → save → reload → verify)
final class EditTokenIntegrationTests: XCTestCase {

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

    // MARK: - Edit Token Integration Tests

    func testEditToken_EditIssuerAndAccount_PersistsChanges() throws {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken(issuer: "GitHub", account: "user@example.com")
        vault.addToken(originalToken)

        // Simulate editing
        var editedToken = originalToken
        editedToken.issuer = "GitLab"
        editedToken.account = "newuser@example.com"

        // Act
        vault.updateToken(editedToken)

        // Simulate reload
        let reloadedToken = vault.tokens.first(where: { $0.id == originalToken.id })

        // Assert
        XCTAssertNotNil(reloadedToken, "Token should exist after edit")
        XCTAssertEqual(reloadedToken?.issuer, "GitLab", "Issuer should be updated")
        XCTAssertEqual(reloadedToken?.account, "newuser@example.com", "Account should be updated")
        XCTAssertEqual(reloadedToken?.id, originalToken.id, "Token ID should remain the same")
        XCTAssertEqual(reloadedToken?.secret, originalToken.secret, "Secret should remain unchanged")
    }

    func testEditToken_MultipleEdits_OnlyLastEditPersists() throws {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken(issuer: "GitHub", account: "user@example.com")
        vault.addToken(originalToken)

        // Act - Multiple edits
        var firstEdit = originalToken
        firstEdit.issuer = "GitLab"
        vault.updateToken(firstEdit)

        var secondEdit = originalToken
        secondEdit.issuer = "Bitbucket"
        vault.updateToken(secondEdit)

        var thirdEdit = originalToken
        thirdEdit.issuer = "SourceForge"
        thirdEdit.account = "final@example.com"
        vault.updateToken(thirdEdit)

        // Assert
        let finalToken = vault.tokens.first(where: { $0.id == originalToken.id })
        XCTAssertEqual(finalToken?.issuer, "SourceForge", "Should have last issuer edit")
        XCTAssertEqual(finalToken?.account, "final@example.com", "Should have last account edit")
    }

    func testEditToken_WithMultipleTokens_OnlyEditedTokenChanges() throws {
        // Arrange
        var vault = Vault()
        let token1 = createTestToken(issuer: "GitHub", account: "user1@example.com")
        let token2 = createTestToken(issuer: "Google", account: "user2@example.com")
        let token3 = createTestToken(issuer: "Amazon", account: "user3@example.com")
        vault.addToken(token1)
        vault.addToken(token2)
        vault.addToken(token3)

        // Act - Edit middle token
        var editedToken2 = token2
        editedToken2.issuer = "Google Workspace"
        editedToken2.account = "workspace@example.com"
        vault.updateToken(editedToken2)

        // Assert
        XCTAssertEqual(vault.tokens.count, 3, "Should still have 3 tokens")

        let reloadedToken1 = vault.tokens.first(where: { $0.id == token1.id })
        XCTAssertEqual(reloadedToken1?.issuer, "GitHub", "Token 1 should be unchanged")
        XCTAssertEqual(reloadedToken1?.account, "user1@example.com", "Token 1 account unchanged")

        let reloadedToken2 = vault.tokens.first(where: { $0.id == token2.id })
        XCTAssertEqual(reloadedToken2?.issuer, "Google Workspace", "Token 2 issuer should be updated")
        XCTAssertEqual(reloadedToken2?.account, "workspace@example.com", "Token 2 account should be updated")

        let reloadedToken3 = vault.tokens.first(where: { $0.id == token3.id })
        XCTAssertEqual(reloadedToken3?.issuer, "Amazon", "Token 3 should be unchanged")
        XCTAssertEqual(reloadedToken3?.account, "user3@example.com", "Token 3 account unchanged")
    }

    func testEditToken_UpdatedAtTimestamp_Changes() throws {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken()
        vault.addToken(originalToken)
        let originalUpdatedAt = originalToken.updatedAt

        // Wait to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Act
        var editedToken = originalToken
        editedToken.issuer = "Updated Issuer"
        vault.updateToken(editedToken)

        // Assert
        let reloadedToken = vault.tokens.first(where: { $0.id == originalToken.id })
        XCTAssertNotNil(reloadedToken?.updatedAt, "updatedAt should exist")
        XCTAssertNotEqual(reloadedToken?.updatedAt, originalUpdatedAt, "updatedAt should change")
        XCTAssertGreaterThan(reloadedToken?.updatedAt ?? Date.distantPast, originalUpdatedAt, "New updatedAt should be later")
    }

    func testEditToken_EmptyIssuer_StillPersists() throws {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken(issuer: "GitHub", account: "user@example.com")
        vault.addToken(originalToken)

        // Act - Edit to empty issuer (validation should happen at ViewModel level)
        var editedToken = originalToken
        editedToken.issuer = ""
        vault.updateToken(editedToken)

        // Assert
        let reloadedToken = vault.tokens.first(where: { $0.id == originalToken.id })
        XCTAssertEqual(reloadedToken?.issuer, "", "Empty issuer should be persisted (VM should validate)")
        XCTAssertEqual(reloadedToken?.account, "user@example.com", "Account should remain unchanged")
    }

    func testEditToken_VaultLastModified_Updates() throws {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken()
        vault.addToken(originalToken)
        let originalLastModified = vault.lastModified

        // Wait to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Act
        var editedToken = originalToken
        editedToken.issuer = "Updated"
        vault.updateToken(editedToken)

        // Assert
        XCTAssertNotEqual(vault.lastModified, originalLastModified, "Vault lastModified should update")
        XCTAssertGreaterThan(vault.lastModified, originalLastModified, "New lastModified should be later")
    }

    // MARK: - Edge Cases

    func testEditToken_CancelEdit_NoChanges() throws {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken(issuer: "GitHub", account: "user@example.com")
        vault.addToken(originalToken)

        // Act - Simulate cancel (no updateToken call)
        // Just reload without updating
        let reloadedToken = vault.tokens.first(where: { $0.id == originalToken.id })

        // Assert
        XCTAssertEqual(reloadedToken?.issuer, "GitHub", "Issuer should remain unchanged on cancel")
        XCTAssertEqual(reloadedToken?.account, "user@example.com", "Account should remain unchanged on cancel")
    }

    func testEditToken_SameValues_StillUpdatesTimestamp() throws {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken(issuer: "GitHub", account: "user@example.com")
        vault.addToken(originalToken)
        let originalUpdatedAt = originalToken.updatedAt

        // Wait to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Act - "Edit" with same values
        var editedToken = originalToken
        editedToken.issuer = "GitHub" // Same value
        editedToken.account = "user@example.com" // Same value
        vault.updateToken(editedToken)

        // Assert
        let reloadedToken = vault.tokens.first(where: { $0.id == originalToken.id })
        XCTAssertNotEqual(reloadedToken?.updatedAt, originalUpdatedAt, "updatedAt should still change even with same values")
    }
}
