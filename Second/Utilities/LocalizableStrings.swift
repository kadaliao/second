//
//  LocalizableStrings.swift
//  Second
//
//  Created by Second Team on 2026-01-18.
//

import Foundation

/// Centralized localization keys to avoid typos and improve maintainability
enum L10n {
    // MARK: - Common
    static var settings: String { NSLocalizedString("设置", comment: "") }
    static var cancel: String { NSLocalizedString("取消", comment: "") }
    static var done: String { NSLocalizedString("完成", comment: "") }
    static var save: String { NSLocalizedString("保存", comment: "") }
    static var add: String { NSLocalizedString("添加", comment: "") }
    static var edit: String { NSLocalizedString("编辑", comment: "") }
    static var delete: String { NSLocalizedString("删除", comment: "") }
    static var ok: String { NSLocalizedString("确定", comment: "") }
    static var scan: String { NSLocalizedString("扫描", comment: "") }

    // MARK: - Token List
    static var searchPlaceholder: String { NSLocalizedString("搜索发行方或账户", comment: "") }
    static var addNewToken: String { NSLocalizedString("添加新令牌", comment: "") }
    static var scanQRCode: String { NSLocalizedString("扫描二维码", comment: "") }
    static var manualEntry: String { NSLocalizedString("手动输入", comment: "") }
    static var loading: String { NSLocalizedString("加载中...", comment: "") }
    static var noMatchingTokens: String { NSLocalizedString("没有匹配的令牌", comment: "") }
    static var trySearchingOther: String { NSLocalizedString("尝试搜索其他发行方或账户", comment: "") }
    static var confirmDelete: String { NSLocalizedString("确认删除", comment: "") }
    static var deleted: String { NSLocalizedString("已删除", comment: "") }
    static var copiedToClipboard: String { NSLocalizedString("已复制到剪贴板", comment: "") }
    static var failedToGenerateCode: String { NSLocalizedString("生成验证码失败", comment: "") }
    static var syncing: String { NSLocalizedString("正在同步...", comment: "") }

    static func syncedAt(_ time: String) -> String {
        String(format: NSLocalizedString("同步: %@", comment: ""), time)
    }

    static func confirmDeleteMessage(issuer: String, account: String) -> String {
        String(format: NSLocalizedString("确定要删除 %@ (%@) 吗?此操作无法撤销。", comment: ""), issuer, account)
    }

    // MARK: - Empty State
    static var noAuthenticators: String { NSLocalizedString("还没有验证码", comment: "") }
    static var tapPlusToAdd: String { NSLocalizedString("轻触 + 按钮添加你的第一个账户", comment: "") }
    static var noAuthenticatorsAccessibility: String { NSLocalizedString("还没有验证码。轻触加号按钮添加你的第一个账户", comment: "") }

    // MARK: - Add Token
    static var addAuthenticator: String { NSLocalizedString("添加验证码", comment: "") }
    static var issuerPlaceholder: String { NSLocalizedString("发行方(如:GitHub)", comment: "") }
    static var accountPlaceholder: String { NSLocalizedString("账户(如:user@example.com)", comment: "") }
    static var secretPlaceholder: String { NSLocalizedString("密钥", comment: "") }
    static var cameraPermissionRequired: String { NSLocalizedString("需要相机权限", comment: "") }
    static var allowCameraAccess: String { NSLocalizedString("请在设置中允许访问相机以扫描二维码", comment: "") }
    static var openSettings: String { NSLocalizedString("打开设置", comment: "") }
    static var alignQRCode: String { NSLocalizedString("对准二维码进行扫描", comment: "") }
    static var scanQRCodeToAdd: String { NSLocalizedString("扫描二维码添加令牌", comment: "") }
    static var manuallyEnterToAdd: String { NSLocalizedString("手动输入添加令牌", comment: "") }
    static var chooseMethod: String { NSLocalizedString("选择扫描二维码或手动输入", comment: "") }

    // MARK: - Edit Token
    static var editAuthenticator: String { NSLocalizedString("编辑验证码", comment: "") }
    static var changesWillSync: String { NSLocalizedString("修改将同步到所有设备", comment: "") }

    // MARK: - Settings
    static var sortAccounts: String { NSLocalizedString("账号排序", comment: "") }
    static var manage: String { NSLocalizedString("管理", comment: "") }
    static var iCloudDataExport: String { NSLocalizedString("iCloud 数据导出", comment: "") }
    static var data: String { NSLocalizedString("数据", comment: "") }
    static var version: String { NSLocalizedString("版本号", comment: "") }
    static var about: String { NSLocalizedString("关于", comment: "") }
    static var noAccounts: String { NSLocalizedString("暂无账号", comment: "") }
    static var sortAfterAdding: String { NSLocalizedString("添加账号后即可排序", comment: "") }

    // MARK: - Export
    static var exportiCloudData: String { NSLocalizedString("导出 iCloud 数据", comment: "") }
    static var exportDescription: String { NSLocalizedString("将存储在 iCloud 中的验证码数据导出为 CSV 格式文件,可用于备份或迁移到其他应用。", comment: "") }
    static var currentAccountCount: String { NSLocalizedString("当前账号数量", comment: "") }
    static var exporting: String { NSLocalizedString("导出中...", comment: "") }
    static var exportCSV: String { NSLocalizedString("导出 CSV", comment: "") }
    static var noAccountsToExport: String { NSLocalizedString("暂无可导出的账号", comment: "") }
    static var exportSuccessful: String { NSLocalizedString("导出成功", comment: "") }
    static var csvSaved: String { NSLocalizedString("CSV 文件已保存到文件应用", comment: "") }
    static var exportFailed: String { NSLocalizedString("导出失败", comment: "") }

    // MARK: - Error Messages
    static var pleaseEnterIssuer: String { NSLocalizedString("请输入发行方", comment: "") }
    static var pleaseEnterAccount: String { NSLocalizedString("请输入账户", comment: "") }
    static var pleaseEnterSecret: String { NSLocalizedString("请输入密钥", comment: "") }
    static var invalidSecretFormat: String { NSLocalizedString("密钥格式无效(必须为 Base32 格式)", comment: "") }
    static var tryAgainOrContactSupport: String { NSLocalizedString("请稍后重试或联系支持。", comment: "") }

    static func qrCodeParsingFailed(_ error: String) -> String {
        String(format: NSLocalizedString("二维码解析失败: %@", comment: ""), error)
    }

    // MARK: - Error States
    static var syncedFromiCloud: String { NSLocalizedString("检测到你的验证码数据已从 iCloud 同步", comment: "") }
    static var keyUnavailableGuidance: String { NSLocalizedString("但解密密钥不可用。请确认已开启 iCloud 钥匙串。\n\n前往:设置 → [你的名字] → iCloud → 钥匙串 → 开启", comment: "") }
    static var iCloudSyncFailed: String { NSLocalizedString("iCloud 同步失败", comment: "") }
    static var checkNetworkAndiCloud: String { NSLocalizedString("请检查网络连接和 iCloud 设置。", comment: "") }
    static var unableToDecryptData: String { NSLocalizedString("无法解密数据", comment: "") }
    static var dataCorrupted: String { NSLocalizedString("数据可能已损坏。请联系支持。", comment: "") }
}
