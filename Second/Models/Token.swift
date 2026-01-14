//
//  Token.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation

/// Represents a single 2FA token with TOTP parameters
struct Token: Identifiable, Codable, Equatable {
    let id: UUID
    var issuer: String
    var account: String
    let secret: String // Base32-encoded
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

    enum ValidationError: Error, LocalizedError {
        case emptyIssuer
        case emptyAccount
        case invalidSecret
        case invalidDigits
        case invalidPeriod

        var errorDescription: String? {
            switch self {
            case .emptyIssuer:
                return "发行方不能为空"
            case .emptyAccount:
                return "账户不能为空"
            case .invalidSecret:
                return "密钥格式无效"
            case .invalidDigits:
                return "验证码位数必须为 6 或 8"
            case .invalidPeriod:
                return "时间周期必须为正整数"
            }
        }
    }

    func validate() throws {
        guard !issuer.isEmpty else {
            throw ValidationError.emptyIssuer
        }
        guard !account.isEmpty else {
            throw ValidationError.emptyAccount
        }
        guard digits == 6 || digits == 8 else {
            throw ValidationError.invalidDigits
        }
        guard period > 0 else {
            throw ValidationError.invalidPeriod
        }
    }
}
