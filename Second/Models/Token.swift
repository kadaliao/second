import Foundation

/// Token entity representing a single 2FA account
struct Token: Identifiable, Codable, Equatable {
    let id: UUID
    var issuer: String
    var account: String
    let secret: String
    var digits: Int
    var period: Int
    var algorithm: TOTPAlgorithm
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        issuer: String,
        account: String,
        secret: String,
        digits: Int = 6,
        period: Int = 30,
        algorithm: TOTPAlgorithm = .sha1
    ) {
        self.id = id
        self.issuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        self.account = account.trimmingCharacters(in: .whitespacesAndNewlines)
        self.secret = secret
        self.digits = digits
        self.period = period
        self.algorithm = algorithm
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
