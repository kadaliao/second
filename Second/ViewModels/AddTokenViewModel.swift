//
//  AddTokenViewModel.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation
import AVFoundation

/// ViewModel for adding new tokens
class AddTokenViewModel: ObservableObject {
    @Published var issuer = ""
    @Published var account = ""
    @Published var secret = ""
    @Published var errorMessage: String?
    @Published var showingScanner = false

    var onTokenAdded: ((Token) -> Void)?

    /// Add token manually
    func addManually() {
        errorMessage = nil

        // Validate inputs
        guard !issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = L10n.pleaseEnterIssuer
            return
        }

        guard !account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = L10n.pleaseEnterAccount
            return
        }

        guard !secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = L10n.pleaseEnterSecret
            return
        }

        guard Base32Decoder.isValid(secret) else {
            errorMessage = L10n.invalidSecretFormat
            return
        }

        let token = Token(
            issuer: issuer,
            account: account,
            secret: secret
        )

        onTokenAdded?(token)
    }

    /// Parse QR code
    func parseQRCode(_ code: String) {
        do {
            let token = try QRCodeParser.parse(code)
            onTokenAdded?(token)
        } catch {
            errorMessage = L10n.qrCodeParsingFailed(error.localizedDescription)
            Logger.error("QR code parsing failed: \(error)")
        }
    }

    /// Check camera permission
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}
