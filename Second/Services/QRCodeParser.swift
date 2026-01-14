//
//  QRCodeParser.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation

/// otpauth:// URI parser per Google Authenticator format
struct QRCodeParser {
    
    enum ParseError: Error, LocalizedError {
        case invalidScheme
        case unsupportedType
        case missingSecret
        case invalidSecret
        case unsupportedAlgorithm
        case invalidDigits
        case invalidPeriod

        var errorDescription: String? {
            switch self {
            case .invalidScheme:
                return "无效的 URI 格式（必须为 otpauth://）"
            case .unsupportedType:
                return "不支持的类型（仅支持 TOTP）"
            case .missingSecret:
                return "缺少密钥参数"
            case .invalidSecret:
                return "密钥格式无效"
            case .unsupportedAlgorithm:
                return "不支持的算法（仅支持 SHA1/SHA256/SHA512）"
            case .invalidDigits:
                return "无效的位数（仅支持 6 或 8 位）"
            case .invalidPeriod:
                return "无效的时间周期"
            }
        }
    }

    static func parse(_ uri: String) throws -> Token {
        // Parse URL
        guard let url = URL(string: uri),
              url.scheme?.lowercased() == "otpauth" else {
            throw ParseError.invalidScheme
        }

        // Validate type
        guard url.host?.lowercased() == "totp" else {
            throw ParseError.unsupportedType
        }

        // Parse label
        let label = url.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .removingPercentEncoding ?? ""
        let labelComponents = label.split(separator: ":", maxSplits: 1)

        let issuer: String
        let account: String

        if labelComponents.count == 2 {
            issuer = String(labelComponents[0])
            account = String(labelComponents[1])
        } else {
            issuer = ""
            account = label
        }

        // Parse query parameters
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            throw ParseError.missingSecret
        }

        guard let secret = queryItems.first(where: { $0.name == "secret" })?.value else {
            throw ParseError.missingSecret
        }

        // Validate Base32 secret
        guard Base32Decoder.isValid(secret) else {
            throw ParseError.invalidSecret
        }

        // Parse optional parameters with defaults
        let issuerParam = queryItems.first(where: { $0.name == "issuer" })?.value ?? ""
        let finalIssuer = issuer.isEmpty ? issuerParam : issuer

        let algorithmString = queryItems.first(where: { $0.name == "algorithm" })?.value ?? "SHA1"
        guard let algorithm = TOTPAlgorithm(rawValue: algorithmString.uppercased()) else {
            throw ParseError.unsupportedAlgorithm
        }

        let digitsString = queryItems.first(where: { $0.name == "digits" })?.value ?? "6"
        guard let digits = Int(digitsString), (digits == 6 || digits == 8) else {
            throw ParseError.invalidDigits
        }

        let periodString = queryItems.first(where: { $0.name == "period" })?.value ?? "30"
        guard let period = Int(periodString), period > 0 else {
            throw ParseError.invalidPeriod
        }

        // Create Token
        return Token(
            issuer: finalIssuer.isEmpty ? "未知" : finalIssuer,
            account: account,
            secret: secret,
            digits: digits,
            period: period,
            algorithm: algorithm
        )
    }
}
