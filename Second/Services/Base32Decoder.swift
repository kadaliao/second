import Foundation

/// Base32 decoder per RFC 4648
struct Base32Decoder {
    private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

    enum DecodeError: LocalizedError {
        case invalidCharacter(Character)
        case invalidLength

        var errorDescription: String? {
            switch self {
            case .invalidCharacter(let char):
                return "Invalid character '\(char)' in Base32 string. Only A-Z and 2-7 are allowed."
            case .invalidLength:
                return "Invalid Base32 string length."
            }
        }
    }

    static func decode(_ encoded: String) throws -> Data {
        let cleaned = encoded.uppercased().replacingOccurrences(of: "=", with: "")
        guard !cleaned.isEmpty else { return Data() }

        var bits = ""
        for char in cleaned {
            guard let index = alphabet.firstIndex(of: char) else {
                throw DecodeError.invalidCharacter(char)
            }
            let value = alphabet.distance(from: alphabet.startIndex, to: index)
            let binary = String(value, radix: 2)
            bits += String(repeating: "0", count: 5 - binary.count) + binary
        }

        var bytes = [UInt8]()
        for i in stride(from: 0, to: bits.count, by: 8) {
            let end = min(i + 8, bits.count)
            let byte = bits[bits.index(bits.startIndex, offsetBy: i)..<bits.index(bits.startIndex, offsetBy: end)]
            if byte.count == 8, let value = UInt8(byte, radix: 2) {
                bytes.append(value)
            }
        }

        return Data(bytes)
    }
}
