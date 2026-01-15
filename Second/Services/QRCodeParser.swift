import Foundation

/// OTPAuth URI parser for QR code scanning
struct OTPAuthURI {

    enum ParseError: LocalizedError {
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
                return "Invalid QR code format. Must be an otpauth:// URL."
            case .unsupportedType:
                return "Only TOTP tokens are supported."
            case .missingSecret:
                return "QR code is missing the secret key."
            case .invalidSecret:
                return "Invalid secret key format. Must be Base32 encoded."
            case .unsupportedAlgorithm:
                return "Unsupported algorithm. Only SHA1, SHA256, and SHA512 are supported."
            case .invalidDigits:
                return "Invalid digits parameter. Must be 6 or 8."
            case .invalidPeriod:
                return "Invalid period parameter. Must be greater than 0."
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
        guard isValidBase32(secret) else {
            throw ParseError.invalidSecret
        }

        // Parse optional parameters
        let issuerParam = queryItems.first(where: { $0.name == "issuer" })?.value ?? ""
        let finalIssuer = issuer.isEmpty ? issuerParam : issuer

        let algorithmString = queryItems.first(where: { $0.name == "algorithm" })?.value ?? "SHA1"
        guard let algorithm = TOTPAlgorithm(rawValue: algorithmString) else {
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

        return Token(
            issuer: finalIssuer,
            account: account,
            secret: secret,
            digits: digits,
            period: period,
            algorithm: algorithm
        )
    }

    private static func isValidBase32(_ string: String) -> Bool {
        let base32Chars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=")
        return string.uppercased().unicodeScalars.allSatisfy { base32Chars.contains($0) }
    }
}
