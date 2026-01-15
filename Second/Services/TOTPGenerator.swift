import Foundation
import CryptoKit

/// TOTP generator per RFC 6238
struct TOTPGenerator {

    enum GenerateError: LocalizedError {
        case invalidSecret
        case invalidParameters

        var errorDescription: String? {
            switch self {
            case .invalidSecret:
                return "Invalid secret key. Cannot generate TOTP code."
            case .invalidParameters:
                return "Invalid TOTP parameters."
            }
        }
    }

    func generate(
        secret: String,
        date: Date = Date(),
        digits: Int = 6,
        period: Int = 30,
        algorithm: TOTPAlgorithm = .sha1
    ) throws -> String {
        // Decode Base32 secret
        let secretData = try Base32Decoder.decode(secret)

        // Calculate counter (time step)
        let counter = UInt64(date.timeIntervalSince1970) / UInt64(period)
        let counterData = withUnsafeBytes(of: counter.bigEndian) { Data($0) }

        // Generate HMAC
        let key = SymmetricKey(data: secretData)
        let hmac: Data

        switch algorithm {
        case .sha1:
            hmac = Data(HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key))
        case .sha256:
            hmac = Data(HMAC<SHA256>.authenticationCode(for: counterData, using: key))
        case .sha512:
            hmac = Data(HMAC<SHA512>.authenticationCode(for: counterData, using: key))
        }

        // Dynamic truncation
        let offset = Int(hmac.last! & 0x0f)
        let truncatedHash = hmac.subdata(in: offset..<offset+4)
        var number = truncatedHash.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
        number &= 0x7fffffff

        let otp = number % UInt32(pow(10, Double(digits)))
        return String(format: "%0\(digits)d", otp)
    }
}
