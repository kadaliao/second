//
//  iCloudExportViewModel.swift
//  Second
//
//  Created by Second Team on 2026-01-17.
//

import Foundation
import CryptoKit

/// ViewModel for iCloud data export
class iCloudExportViewModel: ObservableObject {
    @Published var tokenCount: Int = 0
    @Published var isExporting: Bool = false
    @Published var showingSuccess: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String?
    @Published var showingShareSheet: Bool = false
    @Published var exportURL: URL?

    private let iCloudService = iCloudSyncService()
    private var vault: Vault?

    /// Load token count from iCloud
    func loadTokenCount() {
        do {
            // Load vault key
            guard KeychainService.vaultKeyExists() else {
                tokenCount = 0
                return
            }

            let vaultKey = try KeychainService.loadVaultKey()

            // Load encrypted vault from iCloud
            if iCloudService.encryptedVaultExists() {
                let encryptedData = try iCloudService.loadEncryptedVault()
                vault = try EncryptionService.decrypt(encryptedData: encryptedData, using: vaultKey)
                tokenCount = vault?.tokens.count ?? 0
                Logger.info("已加载 \(tokenCount) 个令牌用于导出")
            } else {
                tokenCount = 0
            }
        } catch {
            Logger.error("加载令牌数量失败: \(error)")
            tokenCount = 0
        }
    }

    /// Export tokens to CSV format
    func exportToCSV() {
        guard let vault = vault, !vault.tokens.isEmpty else {
            errorMessage = L10n.noAccountsToExport
            showingError = true
            return
        }

        isExporting = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let csvContent = self.generateCSV(from: vault.tokens)
                let fileURL = try self.saveCSVFile(csvContent)

                DispatchQueue.main.async {
                    self.exportURL = fileURL
                    self.showingShareSheet = true
                    self.isExporting = false
                    Logger.info("CSV 导出成功")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "\(L10n.exportFailed): \(error.localizedDescription)"
                    self.showingError = true
                    self.isExporting = false
                    Logger.error("CSV 导出失败: \(error)")
                }
            }
        }
    }

    /// Generate CSV content from tokens
    private func generateCSV(from tokens: [Token]) -> String {
        var csv = "发行方,账户,密钥,算法,位数,周期\n"

        for token in tokens {
            let issuer = escapeCSV(token.issuer)
            let account = escapeCSV(token.account)
            let secret = escapeCSV(token.secret)
            let algorithm = token.algorithm.rawValue
            let digits = String(token.digits)
            let period = String(token.period)

            csv += "\(issuer),\(account),\(secret),\(algorithm),\(digits),\(period)\n"
        }

        return csv
    }

    /// Escape CSV field
    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }

    /// Save CSV file to temporary directory
    private func saveCSVFile(_ content: String) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "second_tokens_\(timestamp).csv"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }
}
