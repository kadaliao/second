import Foundation
import CryptoKit

/// TOTP algorithm enumeration
/// Supports SHA1, SHA256, SHA512 per RFC 6238
enum TOTPAlgorithm: String, Codable, CaseIterable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}
