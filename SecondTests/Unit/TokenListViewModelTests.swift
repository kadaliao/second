//
//  TokenListViewModelTests.swift
//  SecondTests
//
//  Created by Second Team on 2026-01-15.
//

import XCTest
import Combine
@testable import Second

final class TokenListViewModelTests: XCTestCase {
    
    var viewModel: TokenListViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = TokenListViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_StartsWithEmptyTokens() {
        XCTAssertEqual(viewModel.tokens.count, 0)
    }
    
    func testInit_SearchTextIsEmpty() {
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    func testInit_IsNotLoading() {
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testInit_NoErrorMessage() {
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Search Filter Tests
    
    func testFilteredTokens_EmptySearch_ReturnsAllTokens() {
        viewModel.tokens = [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "JBSWY3DPEHPK3PXP")
        ]
        
        viewModel.searchText = ""
        
        XCTAssertEqual(viewModel.filteredTokens.count, 2)
    }
    
    func testFilteredTokens_SearchByIssuer_ReturnsMatchingTokens() {
        viewModel.tokens = [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "GitLab", account: "user@gitlab.com", secret: "JBSWY3DPEHPK3PXP")
        ]
        
        viewModel.searchText = "Git"
        
        XCTAssertEqual(viewModel.filteredTokens.count, 2)
        XCTAssertTrue(viewModel.filteredTokens.contains(where: { $0.issuer == "GitHub" }))
        XCTAssertTrue(viewModel.filteredTokens.contains(where: { $0.issuer == "GitLab" }))
    }
    
    func testFilteredTokens_SearchByAccount_ReturnsMatchingTokens() {
        viewModel.tokens = [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "GitLab", account: "admin@gitlab.com", secret: "JBSWY3DPEHPK3PXP")
        ]
        
        viewModel.searchText = "admin"
        
        XCTAssertEqual(viewModel.filteredTokens.count, 1)
        XCTAssertEqual(viewModel.filteredTokens[0].account, "admin@gitlab.com")
    }
    
    func testFilteredTokens_CaseInsensitive_Works() {
        viewModel.tokens = [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP")
        ]
        
        viewModel.searchText = "github"
        XCTAssertEqual(viewModel.filteredTokens.count, 1)
        
        viewModel.searchText = "GITHUB"
        XCTAssertEqual(viewModel.filteredTokens.count, 1)
        
        viewModel.searchText = "GiThUb"
        XCTAssertEqual(viewModel.filteredTokens.count, 1)
    }
    
    func testFilteredTokens_PartialMatch_Works() {
        viewModel.tokens = [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP")
        ]
        
        viewModel.searchText = "Git"
        XCTAssertEqual(viewModel.filteredTokens.count, 1)
        
        viewModel.searchText = "Hub"
        XCTAssertEqual(viewModel.filteredTokens.count, 1)
        
        viewModel.searchText = "user@"
        XCTAssertEqual(viewModel.filteredTokens.count, 1)
    }
    
    func testFilteredTokens_NoMatch_ReturnsEmpty() {
        viewModel.tokens = [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "JBSWY3DPEHPK3PXP")
        ]
        
        viewModel.searchText = "Amazon"
        
        XCTAssertEqual(viewModel.filteredTokens.count, 0)
    }
    
    func testFilteredTokens_SearchBothIssuerAndAccount_Works() {
        viewModel.tokens = [
            Token(issuer: "GitHub", account: "developer@github.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "JBSWY3DPEHPK3PXP")
        ]
        
        // Should match both issuer "GitHub" and account containing "github"
        viewModel.searchText = "github"
        
        XCTAssertEqual(viewModel.filteredTokens.count, 1)
        XCTAssertEqual(viewModel.filteredTokens[0].issuer, "GitHub")
    }
    
    // MARK: - Add Token Tests
    
    func testAddToken_AddsToTokensList() {
        let token = Token(issuer: "Test", account: "test@test.com", secret: "JBSWY3DPEHPK3PXP")
        
        viewModel.addToken(token)
        
        XCTAssertEqual(viewModel.tokens.count, 1)
        XCTAssertEqual(viewModel.tokens[0].issuer, "Test")
    }
    
    func testAddToken_MultipleTokens_PreservesOrder() {
        let token1 = Token(issuer: "A", account: "a@test.com", secret: "JBSWY3DPEHPK3PXP")
        let token2 = Token(issuer: "B", account: "b@test.com", secret: "JBSWY3DPEHPK3PXP")
        let token3 = Token(issuer: "C", account: "c@test.com", secret: "JBSWY3DPEHPK3PXP")
        
        viewModel.addToken(token1)
        viewModel.addToken(token2)
        viewModel.addToken(token3)
        
        XCTAssertEqual(viewModel.tokens.count, 3)
        XCTAssertEqual(viewModel.tokens[0].issuer, "A")
        XCTAssertEqual(viewModel.tokens[1].issuer, "B")
        XCTAssertEqual(viewModel.tokens[2].issuer, "C")
    }
    
    // MARK: - Delete Token Tests
    
    func testDeleteToken_RemovesFromList() {
        viewModel.tokens = [
            Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "Google", account: "user@gmail.com", secret: "JBSWY3DPEHPK3PXP")
        ]
        
        viewModel.deleteToken(at: IndexSet(integer: 0))
        
        XCTAssertEqual(viewModel.tokens.count, 1)
        XCTAssertEqual(viewModel.tokens[0].issuer, "Google")
    }
    
    func testDeleteToken_WithSearchFilter_DeletesCorrectToken() {
        let token1 = Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP")
        let token2 = Token(issuer: "Google", account: "user@gmail.com", secret: "JBSWY3DPEHPK3PXP")
        let token3 = Token(issuer: "GitLab", account: "user@gitlab.com", secret: "JBSWY3DPEHPK3PXP")
        
        viewModel.tokens = [token1, token2, token3]
        
        // Search for "Git" - should show GitHub and GitLab
        viewModel.searchText = "Git"
        XCTAssertEqual(viewModel.filteredTokens.count, 2)
        
        // Delete first item in filtered list (GitHub)
        viewModel.deleteToken(at: IndexSet(integer: 0))
        
        // GitHub should be deleted, Google and GitLab remain
        XCTAssertEqual(viewModel.tokens.count, 2)
        XCTAssertFalse(viewModel.tokens.contains(where: { $0.issuer == "GitHub" }))
        XCTAssertTrue(viewModel.tokens.contains(where: { $0.issuer == "Google" }))
        XCTAssertTrue(viewModel.tokens.contains(where: { $0.issuer == "GitLab" }))
    }
    
    func testDeleteToken_MultipleIndices_DeletesAll() {
        viewModel.tokens = [
            Token(issuer: "A", account: "a@test.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "B", account: "b@test.com", secret: "JBSWY3DPEHPK3PXP"),
            Token(issuer: "C", account: "c@test.com", secret: "JBSWY3DPEHPK3PXP")
        ]
        
        viewModel.deleteToken(at: IndexSet([0, 2]))
        
        XCTAssertEqual(viewModel.tokens.count, 1)
        XCTAssertEqual(viewModel.tokens[0].issuer, "B")
    }
    
    // MARK: - Copy Code Tests
    
    func testCopyCode_ValidToken_SetsToastMessage() {
        let token = Token(issuer: "GitHub", account: "user@github.com", secret: "JBSWY3DPEHPK3PXP")
        
        let expectation = expectation(description: "Toast message set")
        viewModel.$toastMessage
            .dropFirst()
            .sink { message in
                if message == "已复制到剪贴板" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.copyCode(for: token)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCopyCode_InvalidToken_SetsErrorMessage() {
        let token = Token(issuer: "Test", account: "test", secret: "INVALID!@#$")
        
        viewModel.copyCode(for: token)
        
        XCTAssertEqual(viewModel.toastMessage, "生成验证码失败")
    }
    
    // MARK: - Search Performance Tests
    
    func testFilterPerformance_50Tokens() {
        // Create 50 tokens
        viewModel.tokens = (0..<50).map { index in
            Token(
                issuer: "Service\(index)",
                account: "user\(index)@example.com",
                secret: "JBSWY3DPEHPK3PXP"
            )
        }
        
        measure {
            for _ in 0..<1000 {
                viewModel.searchText = "Service"
                _ = viewModel.filteredTokens
                viewModel.searchText = ""
            }
        }
        
        // Should complete < 100ms per 1000 searches (requirement: <100ms response)
    }
    
    func testFilterPerformance_100Tokens() {
        viewModel.tokens = (0..<100).map { index in
            Token(
                issuer: "Service\(index)",
                account: "user\(index)@example.com",
                secret: "JBSWY3DPEHPK3PXP"
            )
        }
        
        measure {
            for _ in 0..<100 {
                viewModel.searchText = "user50"
                _ = viewModel.filteredTokens
            }
        }
    }
}
