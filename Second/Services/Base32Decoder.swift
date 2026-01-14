//
//  Base32Decoder.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation

/// Base32 decoder implementing RFC 4648 with performance optimizations
///
/// Decodes Base32-encoded strings (commonly used in TOTP secrets) to binary data.
/// Uses lookup table for O(1) character conversion and bit-shifting for efficient decoding.
///
/// - Note: Performance optimized with pre-computed lookup table and buffer-based decoding
struct Base32Decoder {
    private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

    // Lookup table for fast character-to-value conversion
    private static let lookupTable: [Character: UInt8] = {
        var table = [Character: UInt8]()
        for (index, char) in alphabet.enumerated() {
            table[char] = UInt8(index)
        }
        return table
    }()

    enum DecodingError: Error, LocalizedError {
        case invalidCharacter(Character)
        case invalidLength

        var errorDescription: String? {
            switch self {
            case .invalidCharacter(let char):
                return "无效的 Base32 字符: \(char)"
            case .invalidLength:
                return "Base32 字符串长度无效"
            }
        }
    }

    /// Decode Base32-encoded string to binary data
    ///
    /// - Parameter encoded: Base32-encoded string (case-insensitive, padding optional)
    /// - Returns: Decoded binary data
    /// - Throws: `DecodingError.invalidCharacter` if string contains invalid Base32 characters
    ///
    /// - Note: Automatically handles padding ('=') and whitespace. Case-insensitive.
    static func decode(_ encoded: String) throws -> Data {
        let cleaned = encoded
            .uppercased()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: " ", with: "")

        // Pre-allocate array for better performance
        var bytes = [UInt8]()
        bytes.reserveCapacity((cleaned.count * 5) / 8)

        var buffer: UInt64 = 0
        var bitsInBuffer = 0

        for char in cleaned {
            guard let value = lookupTable[char] else {
                throw DecodingError.invalidCharacter(char)
            }

            buffer = (buffer << 5) | UInt64(value)
            bitsInBuffer += 5

            if bitsInBuffer >= 8 {
                bitsInBuffer -= 8
                bytes.append(UInt8((buffer >> bitsInBuffer) & 0xFF))
            }
        }

        return Data(bytes)
    }

    /// Validate if a string is valid Base32 encoding
    ///
    /// - Parameter encoded: String to validate
    /// - Returns: `true` if the string contains only valid Base32 characters, `false` otherwise
    ///
    /// - Note: Accepts padding ('=') and whitespace. Case-insensitive.
    static func isValid(_ encoded: String) -> Bool {
        let cleaned = encoded
            .uppercased()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard !cleaned.isEmpty else { return false }

        for char in cleaned {
            if !alphabet.contains(char) {
                return false
            }
        }

        return true
    }
}
