//
//  EditTokenViewModel.swift
//  Second
//
//  Created by Second Team on 2026-01-17.
//

import Foundation
import Combine

/// ViewModel for editing existing tokens
class EditTokenViewModel: ObservableObject {
    @Published var issuer: String
    @Published var account: String
    @Published var errorMessage: String?

    private let originalToken: Token
    private var onSave: ((Token) -> Void)?

    /// Initialize with token to edit
    init(token: Token, onSave: ((Token) -> Void)? = nil) {
        self.originalToken = token
        self.issuer = token.issuer
        self.account = token.account
        self.onSave = onSave
    }

    /// Validation for edit form
    var isValid: Bool {
        !issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Check if any changes were made
    var hasChanges: Bool {
        issuer.trimmingCharacters(in: .whitespacesAndNewlines) != originalToken.issuer ||
        account.trimmingCharacters(in: .whitespacesAndNewlines) != originalToken.account
    }

    /// Save edited token
    func save() {
        errorMessage = nil

        // Validate
        guard isValid else {
            errorMessage = "发行方和账户不能为空"
            return
        }

        // Trim whitespace
        let trimmedIssuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAccount = account.trimmingCharacters(in: .whitespacesAndNewlines)

        // Create updated token (preserve ID, secret, and TOTP parameters)
        var updatedToken = originalToken
        updatedToken.issuer = trimmedIssuer
        updatedToken.account = trimmedAccount
        updatedToken.updatedAt = Date()

        // Call save callback
        onSave?(updatedToken)

        Logger.info("令牌已更新: \(trimmedIssuer) (\(trimmedAccount))")
    }

    /// Cancel edit (for explicit cancel actions)
    func cancel() {
        Logger.info("编辑已取消")
    }
}
