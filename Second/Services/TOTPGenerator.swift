//
//  TOTPGenerator.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation
import CryptoKit

/// TOTP (Time-Based One-Time Password) generator implementing RFC 6238
///
/// Generates time-based verification codes using HMAC-based algorithm.
/// Supports SHA1, SHA256, and SHA512 algorithms with 6 or 8 digit codes.
struct TOTPGenerator {

    // Pre-computed modulo values for performance
    private static let modulo6 = UInt32(1_000_000)
    private static let modulo8 = UInt32(100_000_000)

    /// Generate TOTP code for a given token at a specific time
    ///
    /// - Parameters:
    ///   - token: The token containing secret, algorithm, and period configuration
    ///   - time: The time to generate the code for (defaults to current time)
    /// - Returns: A formatted TOTP code string, or nil if generation fails
    ///
    /// - Note: Uses optimized Base32 decoding and pre-computed modulo values for performance (<50ms)
    static func generate(token: Token, time: Date = Date()) -> String? {
        guard let secretData = try? Base32Decoder.decode(token.secret) else {
            return nil
        }

        let counter = UInt64(time.timeIntervalSince1970) / UInt64(token.period)
        let counterData = withUnsafeBytes(of: counter.bigEndian) { Data($0) }

        let key = SymmetricKey(data: secretData)
        let hmac = token.algorithm.generateHMAC(for: counterData, using: key)

        // Dynamic truncation per RFC 4226
        guard let lastByte = hmac.last else { return nil }
        let offset = Int(lastByte & 0x0f)
        guard hmac.count >= offset + 4 else { return nil }

        let truncatedHash = hmac.subdata(in: offset..<offset+4)
        var number = truncatedHash.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
        number &= 0x7fffffff

        // Use pre-computed modulo values instead of pow()
        let modulo = token.digits == 6 ? modulo6 : modulo8
        let otp = number % modulo
        return String(format: "%0\(token.digits)d", otp)
    }

    /// Calculate remaining seconds in the current time period
    ///
    /// - Parameters:
    ///   - token: The token containing the period configuration
    ///   - time: The time to calculate from (defaults to current time)
    /// - Returns: Number of seconds remaining until the next code rotation
    static func timeRemaining(for token: Token, at time: Date = Date()) -> Int {
        let elapsed = Int(time.timeIntervalSince1970) % token.period
        return token.period - elapsed
    }

    /// Format TOTP code with spacing for better readability
    ///
    /// - Parameter code: The raw TOTP code string
    /// - Returns: Formatted code with spacing (e.g., "123 456" for 6 digits, "1234 5678" for 8 digits)
    ///
    /// - Note: Only formats 6 or 8 digit codes; returns original string for other lengths
    static func format(code: String) -> String {
        guard code.count == 6 || code.count == 8 else { return code }
        
        if code.count == 6 {
            let mid = code.index(code.startIndex, offsetBy: 3)
            return String(code[..<mid]) + " " + String(code[mid...])
        } else {
            let mid = code.index(code.startIndex, offsetBy: 4)
            return String(code[..<mid]) + " " + String(code[mid...])
        }
    }
}
