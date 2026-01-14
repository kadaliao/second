//
//  iCloudSyncService.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation

/// iCloud Key-Value Store sync service
class iCloudSyncService {
    
    private static let vaultKey = "vault"
    private let store = NSUbiquitousKeyValueStore.default

    enum SyncError: Error, LocalizedError {
        case unableToSave
        case unableToLoad
        case noDataFound

        var errorDescription: String? {
            switch self {
            case .unableToSave:
                return "无法保存到 iCloud"
            case .unableToLoad:
                return "无法从 iCloud 加载"
            case .noDataFound:
                return "iCloud 中未找到数据"
            }
        }
    }

    /// Save encrypted vault to iCloud
    func saveEncryptedVault(_ data: Data) throws {
        store.set(data, forKey: Self.vaultKey)
        store.synchronize()
    }

    /// Load encrypted vault from iCloud
    func loadEncryptedVault() throws -> Data {
        guard let data = store.data(forKey: Self.vaultKey) else {
            throw SyncError.noDataFound
        }
        return data
    }

    /// Check if encrypted vault exists in iCloud
    func encryptedVaultExists() -> Bool {
        return store.data(forKey: Self.vaultKey) != nil
    }

    /// Delete encrypted vault from iCloud
    func deleteEncryptedVault() {
        store.removeObject(forKey: Self.vaultKey)
        store.synchronize()
    }

    /// Observe external changes from other devices
    func observeExternalChanges(handler: @escaping () -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { _ in
            handler()
        }
    }

    /// Remove observer
    func removeObserver(_ observer: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(observer)
    }
}
