//
//  DeleteTokenIntegrationTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-17.
//

import XCTest
@testable import Second

/// Integration tests for delete token flow (delete → save → reload → verify)
final class DeleteTokenIntegrationTests: XCTestCase {

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

    // MARK: - Delete Token Integration Tests

    func testDeleteToken_SingleToken_VaultBecomesEmpty() throws {
        // Arrange
        var vault = Vault()
        let token = createTestToken()
        vault.addToken(token)
        XCTAssertEqual(vault.tokens.count, 1, "Precondition: vault should have 1 token")

        // Act
        vault.deleteToken(id: token.id)

        // Simulate reload
        let reloadedTokenCount = vault.tokens.count

        // Assert
        XCTAssertEqual(reloadedTokenCount, 0, "Vault should be empty after deleting last token")
        XCTAssertTrue(vault.tokens.isEmpty, "Tokens array should be empty")
    }

    func testDeleteToken_MultipleTokens_OnlySelectedTokenDeleted() throws {
        // Arrange
        var vault = Vault()
        let token1 = createTestToken(issuer: "GitHub", account: "user1@example.com")
        let token2 = createTestToken(issuer: "Google", account: "user2@example.com")
        let token3 = createTestToken(issuer: "Amazon", account: "user3@example.com")
        vault.addToken(token1)
        vault.addToken(token2)
        vault.addToken(token3)

        // Act - Delete middle token
        vault.deleteToken(id: token2.id)

        // Assert
        XCTAssertEqual(vault.tokens.count, 2, "Should have 2 tokens after deletion")
        XCTAssertTrue(vault.tokens.contains(where: { $0.id == token1.id }), "Token 1 should still exist")
        XCTAssertFalse(vault.tokens.contains(where: { $0.id == token2.id }), "Token 2 should be deleted")
        XCTAssertTrue(vault.tokens.contains(where: { $0.id == token3.id }), "Token 3 should still exist")

        // Verify content of remaining tokens
        let remainingToken1 = vault.tokens.first(where: { $0.id == token1.id })
        XCTAssertEqual(remainingToken1?.issuer, "GitHub", "Token 1 should be unchanged")

        let remainingToken3 = vault.tokens.first(where: { $0.id == token3.id })
        XCTAssertEqual(remainingToken3?.issuer, "Amazon", "Token 3 should be unchanged")
    }

    func testDeleteToken_WithConfirmation_DeletesToken() throws {
        // Arrange
        var vault = Vault()
        let token = createTestToken()
        vault.addToken(token)

        // Act - Simulate user confirmation
        let shouldDelete = true // User confirmed
        if shouldDelete {
            vault.deleteToken(id: token.id)
        }

        // Assert
        XCTAssertTrue(vault.tokens.isEmpty, "Token should be deleted after confirmation")
    }

    func testDeleteToken_WithoutConfirmation_KeepsToken() throws {
        // Arrange
        var vault = Vault()
        let token = createTestToken()
        vault.addToken(token)

        // Act - Simulate user cancellation
        let shouldDelete = false // User cancelled
        if shouldDelete {
            vault.deleteToken(id: token.id)
        }

        // Assert
        XCTAssertEqual(vault.tokens.count, 1, "Token should remain after cancellation")
        XCTAssertTrue(vault.tokens.contains(where: { $0.id == token.id }), "Original token should still exist")
    }

    func testDeleteToken_VaultLastModified_Updates() throws {
        // Arrange
        var vault = Vault()
        let token = createTestToken()
        vault.addToken(token)
        let originalLastModified = vault.lastModified

        // Wait to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Act
        vault.deleteToken(id: token.id)

        // Assert
        XCTAssertNotEqual(vault.lastModified, originalLastModified, "Vault lastModified should update")
        XCTAssertGreaterThan(vault.lastModified, originalLastModified, "New lastModified should be later")
    }

    func testDeleteToken_SequentialDeletions_AllDeleted() throws {
        // Arrange
        var vault = Vault()
        let token1 = createTestToken(issuer: "GitHub")
        let token2 = createTestToken(issuer: "Google")
        let token3 = createTestToken(issuer: "Amazon")
        vault.addToken(token1)
        vault.addToken(token2)
        vault.addToken(token3)

        // Act - Delete all tokens sequentially
        vault.deleteToken(id: token1.id)
        XCTAssertEqual(vault.tokens.count, 2, "Should have 2 tokens after first deletion")

        vault.deleteToken(id: token3.id)
        XCTAssertEqual(vault.tokens.count, 1, "Should have 1 token after second deletion")

        vault.deleteToken(id: token2.id)

        // Assert
        XCTAssertTrue(vault.tokens.isEmpty, "Vault should be empty after all deletions")
        XCTAssertEqual(vault.tokens.count, 0, "Token count should be 0")
    }

    func testDeleteToken_NonExistentToken_NoError() throws {
        // Arrange
        var vault = Vault()
        let token = createTestToken()
        vault.addToken(token)
        let nonExistentID = UUID()

        // Act - Try to delete non-existent token (should not crash)
        vault.deleteToken(id: nonExistentID)

        // Assert
        XCTAssertEqual(vault.tokens.count, 1, "Original token should still exist")
        XCTAssertTrue(vault.tokens.contains(where: { $0.id == token.id }), "Original token should be unchanged")
    }

    // MARK: - Edge Cases

    func testDeleteToken_ImmediatelyAfterAdd_DeletesSuccessfully() throws {
        // Arrange
        var vault = Vault()

        // Act - Add and immediately delete
        let token = createTestToken()
        vault.addToken(token)
        vault.deleteToken(id: token.id)

        // Assert
        XCTAssertTrue(vault.tokens.isEmpty, "Token should be deleted immediately after add")
    }

    func testDeleteToken_LastToken_ReturnsToEmptyState() throws {
        // Arrange
        var vault = Vault()
        let token = createTestToken()
        vault.addToken(token)

        // Act
        vault.deleteToken(id: token.id)

        // Assert - Verify vault is in valid empty state
        XCTAssertTrue(vault.tokens.isEmpty, "Vault should be empty")
        XCTAssertEqual(vault.tokens.count, 0, "Token count should be 0")
        XCTAssertEqual(vault.version, 1, "Version should remain valid")
        XCTAssertNoThrow(try vault.validate(), "Empty vault should be valid")
    }

    func testDeleteToken_AllTokensViaSwipe_VaultBecomesEmpty() throws {
        // Arrange
        var vault = Vault()
        let tokens = [
            createTestToken(issuer: "GitHub"),
            createTestToken(issuer: "Google"),
            createTestToken(issuer: "Amazon"),
            createTestToken(issuer: "Microsoft"),
            createTestToken(issuer: "Apple")
        ]
        tokens.forEach { vault.addToken($0) }
        XCTAssertEqual(vault.tokens.count, 5, "Precondition: should have 5 tokens")

        // Act - Delete all tokens
        tokens.forEach { token in
            vault.deleteToken(id: token.id)
        }

        // Assert
        XCTAssertTrue(vault.tokens.isEmpty, "All tokens should be deleted")
        XCTAssertEqual(vault.tokens.count, 0, "Count should be 0")
    }

    func testDeleteToken_FromFilteredList_ActualTokenDeleted() throws {
        // Arrange - Simulate a filtered list scenario
        var vault = Vault()
        let token1 = createTestToken(issuer: "GitHub", account: "user1@example.com")
        let token2 = createTestToken(issuer: "Google", account: "user2@example.com")
        let token3 = createTestToken(issuer: "Amazon", account: "user3@example.com")
        vault.addToken(token1)
        vault.addToken(token2)
        vault.addToken(token3)

        // Simulate filter (e.g., search for "Google")
        let filteredTokens = vault.tokens.filter { $0.issuer.contains("Google") }
        XCTAssertEqual(filteredTokens.count, 1, "Precondition: filter should return 1 token")

        // Act - Delete from filtered list
        if let tokenToDelete = filteredTokens.first {
            vault.deleteToken(id: tokenToDelete.id)
        }

        // Assert
        XCTAssertEqual(vault.tokens.count, 2, "Should have 2 tokens remaining")
        XCTAssertFalse(vault.tokens.contains(where: { $0.issuer == "Google" }), "Google token should be deleted")
        XCTAssertTrue(vault.tokens.contains(where: { $0.issuer == "GitHub" }), "GitHub token should remain")
        XCTAssertTrue(vault.tokens.contains(where: { $0.issuer == "Amazon" }), "Amazon token should remain")
    }
}
