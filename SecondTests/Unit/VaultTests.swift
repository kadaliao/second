//
//  VaultTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-17.
//

import XCTest
@testable import Second

/// Unit tests for Vault model operations
final class VaultTests: XCTestCase {

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

    // MARK: - Update Token Tests

    func testUpdateToken_Success() {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken(issuer: "GitHub", account: "original@example.com")
        vault.addToken(originalToken)

        // Act
        var updatedToken = originalToken
        updatedToken.issuer = "GitLab"
        updatedToken.account = "updated@example.com"
        vault.updateToken(updatedToken)

        // Assert
        XCTAssertEqual(vault.tokens.count, 1, "Vault should still have 1 token after update")
        XCTAssertEqual(vault.tokens[0].id, originalToken.id, "Token ID should remain the same")
        XCTAssertEqual(vault.tokens[0].issuer, "GitLab", "Issuer should be updated")
        XCTAssertEqual(vault.tokens[0].account, "updated@example.com", "Account should be updated")
        XCTAssertNotEqual(vault.tokens[0].updatedAt, originalToken.updatedAt, "updatedAt should change")
    }

    func testUpdateToken_UpdatesLastModified() {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken()
        vault.addToken(originalToken)
        let originalLastModified = vault.lastModified

        // Wait a bit to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Act
        var updatedToken = originalToken
        updatedToken.issuer = "Updated Issuer"
        vault.updateToken(updatedToken)

        // Assert
        XCTAssertNotEqual(vault.lastModified, originalLastModified, "Vault lastModified should be updated")
        XCTAssertGreaterThan(vault.lastModified, originalLastModified, "New lastModified should be later")
    }

    func testUpdateToken_NonExistentToken_NoEffect() {
        // Arrange
        var vault = Vault()
        let existingToken = createTestToken(issuer: "GitHub")
        vault.addToken(existingToken)

        let nonExistentToken = createTestToken(issuer: "NonExistent")
        let originalCount = vault.tokens.count

        // Act
        vault.updateToken(nonExistentToken)

        // Assert
        XCTAssertEqual(vault.tokens.count, originalCount, "Token count should not change")
        XCTAssertEqual(vault.tokens[0].issuer, "GitHub", "Existing token should be unchanged")
    }

    func testUpdateToken_OnlyIssuer() {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken(issuer: "GitHub", account: "user@example.com")
        vault.addToken(originalToken)

        // Act
        var updatedToken = originalToken
        updatedToken.issuer = "GitLab"
        vault.updateToken(updatedToken)

        // Assert
        XCTAssertEqual(vault.tokens[0].issuer, "GitLab", "Issuer should be updated")
        XCTAssertEqual(vault.tokens[0].account, "user@example.com", "Account should remain unchanged")
        XCTAssertEqual(vault.tokens[0].secret, originalToken.secret, "Secret should remain unchanged")
    }

    func testUpdateToken_OnlyAccount() {
        // Arrange
        var vault = Vault()
        let originalToken = createTestToken(issuer: "GitHub", account: "user@example.com")
        vault.addToken(originalToken)

        // Act
        var updatedToken = originalToken
        updatedToken.account = "newuser@example.com"
        vault.updateToken(updatedToken)

        // Assert
        XCTAssertEqual(vault.tokens[0].issuer, "GitHub", "Issuer should remain unchanged")
        XCTAssertEqual(vault.tokens[0].account, "newuser@example.com", "Account should be updated")
    }

    func testUpdateToken_MultipleTokens_UpdatesCorrectOne() {
        // Arrange
        var vault = Vault()
        let token1 = createTestToken(issuer: "GitHub", account: "user1@example.com")
        let token2 = createTestToken(issuer: "Google", account: "user2@example.com")
        let token3 = createTestToken(issuer: "Amazon", account: "user3@example.com")
        vault.addToken(token1)
        vault.addToken(token2)
        vault.addToken(token3)

        // Act
        var updatedToken2 = token2
        updatedToken2.issuer = "Google Workspace"
        vault.updateToken(updatedToken2)

        // Assert
        XCTAssertEqual(vault.tokens.count, 3, "Should still have 3 tokens")
        XCTAssertEqual(vault.tokens[0].issuer, "GitHub", "Token 1 should be unchanged")
        XCTAssertEqual(vault.tokens[1].issuer, "Google Workspace", "Token 2 should be updated")
        XCTAssertEqual(vault.tokens[2].issuer, "Amazon", "Token 3 should be unchanged")
    }

    // MARK: - Delete Token Tests

    func testDeleteToken_Success() {
        // Arrange
        var vault = Vault()
        let token1 = createTestToken(issuer: "GitHub")
        let token2 = createTestToken(issuer: "Google")
        vault.addToken(token1)
        vault.addToken(token2)

        // Act
        vault.deleteToken(id: token1.id)

        // Assert
        XCTAssertEqual(vault.tokens.count, 1, "Vault should have 1 token after deletion")
        XCTAssertEqual(vault.tokens[0].id, token2.id, "Remaining token should be token2")
        XCTAssertEqual(vault.tokens[0].issuer, "Google", "Remaining token should be Google")
    }

    func testDeleteToken_LastToken_EmptyVault() {
        // Arrange
        var vault = Vault()
        let token = createTestToken()
        vault.addToken(token)

        // Act
        vault.deleteToken(id: token.id)

        // Assert
        XCTAssertTrue(vault.tokens.isEmpty, "Vault should be empty after deleting last token")
        XCTAssertEqual(vault.tokens.count, 0, "Token count should be 0")
    }

    func testDeleteToken_NonExistentToken_NoEffect() {
        // Arrange
        var vault = Vault()
        let token = createTestToken()
        vault.addToken(token)
        let nonExistentID = UUID()

        // Act
        vault.deleteToken(id: nonExistentID)

        // Assert
        XCTAssertEqual(vault.tokens.count, 1, "Vault should still have 1 token")
        XCTAssertEqual(vault.tokens[0].id, token.id, "Original token should remain")
    }

    func testDeleteToken_UpdatesLastModified() {
        // Arrange
        var vault = Vault()
        let token = createTestToken()
        vault.addToken(token)
        let originalLastModified = vault.lastModified

        // Wait a bit to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Act
        vault.deleteToken(id: token.id)

        // Assert
        XCTAssertNotEqual(vault.lastModified, originalLastModified, "Vault lastModified should be updated")
        XCTAssertGreaterThan(vault.lastModified, originalLastModified, "New lastModified should be later")
    }

    func testDeleteToken_MultipleTokens_DeletesCorrectOne() {
        // Arrange
        var vault = Vault()
        let token1 = createTestToken(issuer: "GitHub")
        let token2 = createTestToken(issuer: "Google")
        let token3 = createTestToken(issuer: "Amazon")
        vault.addToken(token1)
        vault.addToken(token2)
        vault.addToken(token3)

        // Act
        vault.deleteToken(id: token2.id)

        // Assert
        XCTAssertEqual(vault.tokens.count, 2, "Should have 2 tokens after deletion")
        XCTAssertEqual(vault.tokens[0].issuer, "GitHub", "Token 1 should remain")
        XCTAssertEqual(vault.tokens[1].issuer, "Amazon", "Token 3 should remain")
        XCTAssertFalse(vault.tokens.contains(where: { $0.id == token2.id }), "Token 2 should be deleted")
    }

    func testDeleteToken_AllTokens_Sequential() {
        // Arrange
        var vault = Vault()
        let token1 = createTestToken(issuer: "GitHub")
        let token2 = createTestToken(issuer: "Google")
        let token3 = createTestToken(issuer: "Amazon")
        vault.addToken(token1)
        vault.addToken(token2)
        vault.addToken(token3)

        // Act & Assert
        vault.deleteToken(id: token1.id)
        XCTAssertEqual(vault.tokens.count, 2, "Should have 2 tokens after first deletion")

        vault.deleteToken(id: token2.id)
        XCTAssertEqual(vault.tokens.count, 1, "Should have 1 token after second deletion")

        vault.deleteToken(id: token3.id)
        XCTAssertTrue(vault.tokens.isEmpty, "Vault should be empty after deleting all tokens")
    }
}
