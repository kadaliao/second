//
//  Vault.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation

/// Encrypted container for all tokens
struct Vault: Codable {
    var tokens: [Token]
    let version: Int
    var lastModified: Date

    init(tokens: [Token] = [], version: Int = 1) {
        self.tokens = tokens
        self.version = version
        self.lastModified = Date()
    }

    mutating func addToken(_ token: Token) {
        tokens.append(token)
        lastModified = Date()
    }

    mutating func updateToken(_ token: Token) {
        if let index = tokens.firstIndex(where: { $0.id == token.id }) {
            var updatedToken = token
            updatedToken.updatedAt = Date()
            tokens[index] = updatedToken
            lastModified = Date()
        }
    }

    mutating func deleteToken(id: UUID) {
        tokens.removeAll(where: { $0.id == id })
        lastModified = Date()
    }

    enum ValidationError: Error {
        case invalidVersion
        case duplicateTokenIDs
    }

    func validate() throws {
        guard version > 0 else {
            throw ValidationError.invalidVersion
        }
        let ids = tokens.map { $0.id }
        guard ids.count == Set(ids).count else {
            throw ValidationError.duplicateTokenIDs
        }
    }
}
