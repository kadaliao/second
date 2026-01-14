//
//  SyncViewModel.swift
//  Second
//
//  Created by Second Team on 2026-01-17.
//

import Foundation
import Combine

/// ViewModel for managing iCloud sync status
class SyncViewModel: ObservableObject {
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    private let iCloudService = iCloudSyncService()

    /// Sync status message for display
    var syncStatusMessage: String {
        if isSyncing {
            return "正在同步..."
        } else if let lastSync = lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            let timeAgo = formatter.localizedString(for: lastSync, relativeTo: Date())
            return "上次同步: \(timeAgo)"
        } else {
            return "未同步"
        }
    }

    /// Indicates if sync is available (iCloud enabled)
    var isSyncAvailable: Bool {
        // NSUbiquitousKeyValueStore is always available, but may fail silently if iCloud is disabled
        // We can check by attempting a read operation
        return true // Simplified - actual availability is determined by successful operations
    }

    /// Start sync operation
    func startSync() {
        isSyncing = true
        syncError = nil
        Logger.info("开始手动同步")
    }

    /// Complete sync operation
    func completeSync(success: Bool, error: String? = nil) {
        isSyncing = false

        if success {
            lastSyncDate = Date()
            syncError = nil
            Logger.info("同步成功")
        } else {
            syncError = error
            Logger.error("同步失败: \(error ?? "未知错误")")
        }
    }

    /// Force synchronize with iCloud
    func forceSynchronize() {
        startSync()

        // NSUbiquitousKeyValueStore.synchronize() returns Bool indicating if sync was attempted
        // Note: This is a request to sync, not a guarantee
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let success = NSUbiquitousKeyValueStore.default.synchronize()

            DispatchQueue.main.async {
                self?.completeSync(success: success)
            }
        }
    }

    /// Clear sync status
    func clearSyncStatus() {
        isSyncing = false
        lastSyncDate = nil
        syncError = nil
    }
}
