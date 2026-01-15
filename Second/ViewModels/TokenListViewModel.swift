import SwiftUI
import Combine

@MainActor
class TokenListViewModel: ObservableObject {
    @Published var vault: Vault = Vault()
    @Published var searchText: String = ""
    @Published var currentCodes: [UUID: String] = [:]
    @Published var timeRemaining: Int = 30
    @Published var errorMessage: String?
    @Published var showAddToken: Bool = false

    private let keychainService: KeychainService
    private let encryptionService: EncryptionService
    private let iCloudSyncService: iCloudSyncService
    private let totpGenerator: TOTPGenerator

    private var timerCancellable: AnyCancellable?
    private var encryptionKey: SymmetricKey?

    init(
        keychainService: KeychainService = KeychainService(),
        encryptionService: EncryptionService = EncryptionService(),
        iCloudSyncService: iCloudSyncService = iCloudSyncService(),
        totpGenerator: TOTPGenerator = TOTPGenerator()
    ) {
        self.keychainService = keychainService
        self.encryptionService = encryptionService
        self.iCloudSyncService = iCloudSyncService
        self.totpGenerator = totpGenerator

        setupTimer()
    }

    var filteredTokens: [Token] {
        if searchText.isEmpty {
            return vault.tokens
        }

        let lowercasedSearch = searchText.lowercased()
        return vault.tokens.filter { token in
            token.issuer.lowercased().contains(lowercasedSearch) ||
            token.account.lowercased().contains(lowercasedSearch)
        }
    }

    private func setupTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCodes()
            }
    }

    private func updateCodes() {
        let now = Date()
        timeRemaining = 30 - (Int(now.timeIntervalSince1970) % 30)

        for token in vault.tokens {
            do {
                let code = try totpGenerator.generate(
                    secret: token.secret,
                    date: now,
                    digits: token.digits,
                    period: token.period,
                    algorithm: token.algorithm
                )
                currentCodes[token.id] = code
            } catch {
                Logger.log("Failed to generate TOTP for token \(token.id)", level: .error)
            }
        }
    }

    func loadVault() async {
        do {
            // Get or generate encryption key
            if let existingKey = try keychainService.loadKey(identifier: "vault_key") {
                encryptionKey = existingKey
            } else {
                let newKey = EncryptionService.generateKey()
                try keychainService.saveKey(newKey, identifier: "vault_key")
                encryptionKey = newKey
            }

            guard let key = encryptionKey else {
                throw VaultError.noEncryptionKey
            }

            // Try to load from iCloud
            if let encryptedData = iCloudSyncService.getData(forKey: "encrypted_vault") {
                let decryptedData = try encryptionService.decrypt(encryptedData, using: key)
                vault = try JSONDecoder().decode(Vault.self, from: decryptedData)
                Logger.log("Vault loaded from iCloud", level: .info)
            } else {
                Logger.log("No vault found, starting with empty vault", level: .info)
            }

            updateCodes()
        } catch {
            errorMessage = "Failed to load vault: \(error.localizedDescription)"
            Logger.log("Failed to load vault: \(error)", level: .error)
        }
    }

    func saveVault() async {
        do {
            guard let key = encryptionKey else {
                throw VaultError.noEncryptionKey
            }

            let vaultData = try JSONEncoder().encode(vault)
            let encryptedData = try encryptionService.encrypt(vaultData, using: key)
            iCloudSyncService.setData(encryptedData, forKey: "encrypted_vault")

            Logger.log("Vault saved to iCloud", level: .info)
        } catch {
            errorMessage = "Failed to save vault: \(error.localizedDescription)"
            Logger.log("Failed to save vault: \(error)", level: .error)
        }
    }

    func addToken(_ token: Token) {
        vault.addToken(token)
        updateCodes()

        Task {
            await saveVault()
        }
    }

    func deleteToken(id: UUID) {
        vault.deleteToken(id: id)
        currentCodes.removeValue(forKey: id)

        Task {
            await saveVault()
        }
    }

    func copyToClipboard(code: String) {
        ClipboardHelper.copy(code)
    }

    enum VaultError: LocalizedError {
        case noEncryptionKey

        var errorDescription: String? {
            switch self {
            case .noEncryptionKey:
                return "No encryption key available"
            }
        }
    }
}
