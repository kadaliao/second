import Foundation

/// Vault entity - encrypted container for all tokens
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
}
