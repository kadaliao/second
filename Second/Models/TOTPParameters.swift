//
//  TOTPParameters.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation
import CryptoKit

/// TOTP algorithm enumeration per RFC 6238
enum TOTPAlgorithm: String, Codable, CaseIterable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"

    /// Map to CryptoKit HMAC algorithm type
    func generateHMAC(for data: Data, using key: SymmetricKey) -> Data {
        switch self {
        case .sha1:
            return Data(HMAC<Insecure.SHA1>.authenticationCode(for: data, using: key))
        case .sha256:
            return Data(HMAC<SHA256>.authenticationCode(for: data, using: key))
        case .sha512:
            return Data(HMAC<SHA512>.authenticationCode(for: data, using: key))
        }
    }
}
