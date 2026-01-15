import SwiftUI
import Combine

@MainActor
class AddTokenViewModel: ObservableObject {
    @Published var issuer: String = ""
    @Published var account: String = ""
    @Published var secret: String = ""
    @Published var digits: Int = 6
    @Published var period: Int = 30
    @Published var algorithm: TOTPAlgorithm = .sha1

    @Published var showScanner: Bool = false
    @Published var errorMessage: String?
    @Published var isProcessing: Bool = false

    private let onTokenAdded: (Token) -> Void

    init(onTokenAdded: @escaping (Token) -> Void) {
        self.onTokenAdded = onTokenAdded
    }

    func handleScannedCode(_ code: String) {
        isProcessing = true
        errorMessage = nil

        do {
            let token = try OTPAuthURI.parse(code)
            onTokenAdded(token)
        } catch {
            errorMessage = "Invalid QR code: \(error.localizedDescription)"
        }

        isProcessing = false
        showScanner = false
    }

    func handleScanError(_ error: Error) {
        errorMessage = "Scanner error: \(error.localizedDescription)"
        showScanner = false
    }

    func addManualToken() {
        errorMessage = nil

        // Validate inputs
        guard !issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Issuer is required"
            return
        }

        guard !account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Account is required"
            return
        }

        guard !secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Secret is required"
            return
        }

        // Validate secret is valid Base32
        let cleanSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .uppercased()

        do {
            _ = try Base32Decoder.decode(cleanSecret)
        } catch {
            errorMessage = "Invalid secret: must be valid Base32"
            return
        }

        // Validate digits
        guard (6...8).contains(digits) else {
            errorMessage = "Digits must be between 6 and 8"
            return
        }

        // Validate period
        guard period > 0 else {
            errorMessage = "Period must be greater than 0"
            return
        }

        // Create token
        let token = Token(
            issuer: issuer.trimmingCharacters(in: .whitespacesAndNewlines),
            account: account.trimmingCharacters(in: .whitespacesAndNewlines),
            secret: cleanSecret,
            digits: digits,
            period: period,
            algorithm: algorithm
        )

        onTokenAdded(token)
    }

    func reset() {
        issuer = ""
        account = ""
        secret = ""
        digits = 6
        period = 30
        algorithm = .sha1
        errorMessage = nil
        isProcessing = false
    }
}
