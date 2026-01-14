//
//  ErrorStateView.swift
//  Second
//
//  Created by Second Team on 2026-01-17.
//

import SwiftUI

/// Error state view for critical errors like missing vault key
struct ErrorStateView: View {
    let message: String
    let systemImage: String
    let guidance: String?

    init(message: String, systemImage: String = "exclamationmark.triangle", guidance: String? = nil) {
        self.message = message
        self.systemImage = systemImage
        self.guidance = guidance
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(Color(.systemOrange))

            Text(message)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let guidance = guidance {
                Text(guidance)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

// MARK: - Convenience Initializers

extension ErrorStateView {
    /// Error state for missing vault key (FR-022, FR-023)
    static var missingVaultKey: ErrorStateView {
        ErrorStateView(
            message: L10n.syncedFromiCloud,
            systemImage: "key.slash",
            guidance: L10n.keyUnavailableGuidance
        )
    }

    /// Error state for sync failure
    static var syncFailure: ErrorStateView {
        ErrorStateView(
            message: L10n.iCloudSyncFailed,
            systemImage: "icloud.slash",
            guidance: L10n.checkNetworkAndiCloud
        )
    }

    /// Error state for decryption failure
    static var decryptionFailure: ErrorStateView {
        ErrorStateView(
            message: L10n.unableToDecryptData,
            systemImage: "lock.slash",
            guidance: L10n.dataCorrupted
        )
    }
}

// MARK: - Preview

#Preview("Missing Vault Key") {
    ErrorStateView.missingVaultKey
}

#Preview("Sync Failure") {
    ErrorStateView.syncFailure
}

#Preview("Decryption Failure") {
    ErrorStateView.decryptionFailure
}

#Preview("Custom Error") {
    ErrorStateView(
        message: L10n.unableToDecryptData,
        systemImage: "exclamationmark.triangle",
        guidance: L10n.dataCorrupted
    )
}
