//
//  TokenListViewModel.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation
import Combine
import CryptoKit

/// Mode for adding tokens
enum AddTokenMode {
    case scan
    case manual
}

/// ViewModel for token list management
class TokenListViewModel: ObservableObject {
    @Published var tokens: [Token] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddToken = false
    @Published var toastMessage: String?
    @Published var addTokenMode: AddTokenMode = .scan
    @Published var showingEditToken = false
    @Published var tokenToEdit: Token?
    @Published var showingDeleteConfirmation = false
    @Published var tokenToDelete: Token?
    @Published var lastSyncDate: Date?
    @Published var isSyncing: Bool = false

    private var vault = Vault()
    private var vaultKey: SymmetricKey?
    private let iCloudService = iCloudSyncService()
    private var syncObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()

    /// Sync status message for UI display
    var syncStatusMessage: String? {
        if isSyncing {
            return L10n.syncing
        } else if let lastSync = lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            let timeAgo = formatter.localizedString(for: lastSync, relativeTo: Date())
            return L10n.syncedAt(timeAgo)
        }
        return nil
    }

    /// Filtered tokens based on search text with fuzzy matching
    var filteredTokens: [Token] {
        if searchText.isEmpty {
            return tokens
        }

        let lowercasedSearch = searchText.lowercased()
        return tokens.filter { token in
            let issuer = token.issuer.lowercased()
            let account = token.account.lowercased()

            // 精确包含匹配
            if issuer.contains(lowercasedSearch) || account.contains(lowercasedSearch) {
                return true
            }

            // 模糊匹配 - 允许字符之间有间隔
            return fuzzyMatch(text: issuer, pattern: lowercasedSearch) ||
                   fuzzyMatch(text: account, pattern: lowercasedSearch)
        }
    }

    /// 模糊匹配算法 - 检查 pattern 的所有字符是否按顺序出现在 text 中
    private func fuzzyMatch(text: String, pattern: String) -> Bool {
        var patternIndex = pattern.startIndex

        for char in text {
            if patternIndex < pattern.endIndex && char == pattern[patternIndex] {
                patternIndex = pattern.index(after: patternIndex)
            }

            if patternIndex == pattern.endIndex {
                return true
            }
        }

        return patternIndex == pattern.endIndex
    }

    init() {
        setupSyncObserver()
    }

    deinit {
        if let observer = syncObserver {
            iCloudService.removeObserver(observer)
        }
    }

    /// Load vault on app launch
    func onAppear() {
        Task {
            await loadVault()
        }
    }

    /// Load vault from iCloud or create new
    @MainActor
    private func loadVault() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load or generate vault key
            if KeychainService.vaultKeyExists() {
                vaultKey = try KeychainService.loadVaultKey()
                Logger.info("钥匙串密钥已加载")
            } else {
                // First launch - generate new key
                let newKey = KeychainService.generateVaultKey()
                try KeychainService.saveVaultKey(newKey)
                vaultKey = newKey
                Logger.info("已生成并保存新的钥匙串密钥")
            }

            guard let key = vaultKey else {
                errorMessage = "无法加载密钥"
                isLoading = false
                return
            }

            // Try to load encrypted vault from iCloud
            if iCloudService.encryptedVaultExists() {
                let encryptedData = try iCloudService.loadEncryptedVault()
                vault = try EncryptionService.decrypt(encryptedData: encryptedData, using: key)
                tokens = vault.tokens
                Logger.info("已从 iCloud 加载 \(tokens.count) 个令牌")
            } else {
                // New user - empty vault
                vault = Vault()
                tokens = []
                Logger.info("创建新的空保险库")
            }
        } catch KeychainService.KeychainError.keyNotFound {
            // Encrypted vault exists but no key - error state
            if iCloudService.encryptedVaultExists() {
                errorMessage = "检测到你的验证码数据已从 iCloud 同步,但解密密钥不可用。请确认已开启 iCloud 钥匙串。"
                Logger.error("保险库存在但密钥缺失")
            }
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
            Logger.error("加载保险库失败: \(error)")
        }

        isLoading = false
    }

    /// Save vault to iCloud
    @MainActor
    func saveVault() async {
        guard let key = vaultKey else {
            Logger.error("无法保存 - 密钥缺失")
            return
        }

        isSyncing = true

        do {
            let encryptedData = try EncryptionService.encrypt(vault: vault, using: key)
            try iCloudService.saveEncryptedVault(encryptedData)
            lastSyncDate = Date()
            isSyncing = false
            Logger.info("保险库已保存到 iCloud")
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            isSyncing = false
            Logger.error("保存保险库失败: \(error)")
        }
    }

    /// Add new token
    func addToken(_ token: Token) {
        vault.addToken(token)
        tokens = vault.tokens

        Task {
            await saveVault()
        }
    }

    /// Update existing token
    func updateToken(_ token: Token) {
        vault.updateToken(token)
        tokens = vault.tokens

        Task {
            await saveVault()
        }

        Logger.info("令牌已更新: \(token.issuer)")
    }

    /// Show edit sheet for token
    func editToken(_ token: Token) {
        tokenToEdit = token
        showingEditToken = true
    }

    /// Request delete confirmation for token
    func requestDeleteToken(_ token: Token) {
        tokenToDelete = token
        showingDeleteConfirmation = true
    }

    /// Confirm and delete token
    func confirmDelete() {
        guard let token = tokenToDelete else { return }

        vault.deleteToken(id: token.id)
        tokens = vault.tokens

        Task {
            await saveVault()
        }

        toastMessage = L10n.deleted

        // Clear toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.toastMessage = nil
        }

        // Clear deletion state
        tokenToDelete = nil
        showingDeleteConfirmation = false

        Logger.info("令牌已删除: \(token.issuer)")
    }

    /// Cancel delete operation
    func cancelDelete() {
        tokenToDelete = nil
        showingDeleteConfirmation = false
    }

    /// Delete token with confirmation (for swipe-to-delete)
    func deleteToken(at offsets: IndexSet) {
        let tokensToDelete = offsets.map { filteredTokens[$0] }
        for token in tokensToDelete {
            vault.deleteToken(id: token.id)
        }
        tokens = vault.tokens

        Task {
            await saveVault()
        }
    }

    /// Copy TOTP code to clipboard
    func copyCode(for token: Token) {
        guard let code = TOTPGenerator.generate(token: token) else {
            toastMessage = L10n.failedToGenerateCode
            return
        }

        ClipboardHelper.copy(code)
        toastMessage = L10n.copiedToClipboard
        
        // Clear toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.toastMessage = nil
        }
    }

    /// Setup sync observer for external changes
    private func setupSyncObserver() {
        syncObserver = iCloudService.observeExternalChanges { [weak self] in
            Task {
                await self?.loadVault()
            }
        }
    }

    /// Move token for reordering
    func moveToken(from source: IndexSet, to destination: Int) {
        vault.tokens.move(fromOffsets: source, toOffset: destination)
        tokens = vault.tokens

        Task {
            await saveVault()
        }

        Logger.info("令牌已重新排序")
    }
}
