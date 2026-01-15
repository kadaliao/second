import Foundation

/// iCloud sync service using NSUbiquitousKeyValueStore
class iCloudSyncService {

    private let store = NSUbiquitousKeyValueStore.default
    private let vaultKey = "vault"

    enum SyncError: Error {
        case saveFailed
        case loadFailed
    }

    func saveVault(_ data: Data) throws {
        store.set(data, forKey: vaultKey)
        store.synchronize()
    }

    func loadVault() throws -> Data? {
        return store.data(forKey: vaultKey)
    }

    func observeChanges(handler: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { _ in
            handler()
        }
    }
}
