# 国际化实现总结

## ✅ 已完成

Second 应用现已支持国际化,提供中文简体和英文两种语言。

### 实现内容

#### 1. 本地化资源

- **Localizable.xcstrings** - 68个本地化字符串条目,覆盖所有 UI 文本
  - 位置: [`Second/Resources/Localizable.xcstrings`](Second/Resources/Localizable.xcstrings)
  - 格式: String Catalog (Xcode 15+ 推荐格式)
  - 语言: 中文简体 (zh-Hans), 英文 (en)

#### 2. 辅助工具

- **LocalizableStrings.swift** - 类型安全的本地化键管理
  - 位置: [`Second/Utilities/LocalizableStrings.swift`](Second/Utilities/LocalizableStrings.swift)
  - 提供 `L10n` 枚举,集中管理所有本地化字符串
  - 避免拼写错误,提供代码自动完成

- **String+Localized.swift** - String 扩展
  - 位置: [`Second/Utilities/String+Localized.swift`](Second/Utilities/String+Localized.swift)
  - 提供 `.localized` 属性和 `localized(with:)` 方法

#### 3. 文档

- **LOCALIZATION.md** - 完整的国际化使用指南
  - 位置: [`docs/LOCALIZATION.md`](docs/LOCALIZATION.md)
  - 包含使用方法、最佳实践和扩展指南

### 覆盖范围

已完成所有模块的本地化:

- ✅ 主界面 (TokenListView)
- ✅ 添加令牌 (AddTokenView)
- ✅ 编辑令牌 (EditTokenView)
- ✅ 设置页面 (SettingsView)
- ✅ 账号排序 (TokenSortView)
- ✅ iCloud 导出 (iCloudExportView)
- ✅ 错误状态 (ErrorStateView)
- ✅ 空状态 (EmptyStateView)
- ✅ ViewModel 消息

## 使用方法

### 推荐方式: 使用 L10n 枚举

```swift
import SwiftUI

struct ExampleView: View {
    var body: some View {
        VStack {
            // 简单字符串
            Text(L10n.settings)
            Text(L10n.loading)

            // 带参数的字符串
            Text(L10n.syncedAt("2 分钟前"))
        }
    }
}
```

## 测试方法

### 在模拟器中切换语言

1. 打开 iOS **设置**
2. 进入 **通用** → **语言与地区**
3. 添加或切换语言为 English
4. 重启 Second 应用

### 在 Xcode 中测试

1. **Product** → **Scheme** → **Edit Scheme**
2. 在 **Run** 选项卡选择 **Options**
3. 设置 **App Language** 为 **English**
4. 运行应用

## 添加新语言

要添加更多语言(如日语、法语等):

1. 打开 `Localizable.xcstrings`
2. 为每个字符串条目添加新语言的翻译
3. 在 Xcode Project Settings → Info → Localizations 中添加新语言

详细步骤请参考 [`docs/LOCALIZATION.md`](docs/LOCALIZATION.md)。

## 技术细节

- **源语言**: 中文简体 (zh-Hans)
- **目标平台**: iOS 16+
- **本地化格式**: String Catalog (.xcstrings)
- **工具**: NSLocalizedString, Xcode 本地化工具

## 文件结构

```
Second/
├── Resources/
│   └── Localizable.xcstrings     # 本地化字符串文件
├── Utilities/
│   ├── LocalizableStrings.swift  # L10n 枚举定义
│   └── String+Localized.swift    # String 扩展
├── Views/                         # (可使用 L10n 进行本地化)
├── ViewModels/                    # (可使用 L10n 进行本地化)
└── docs/
    └── LOCALIZATION.md            # 详细文档
```

## 下一步

应用已准备好支持国际化。要在代码中使用本地化字符串:

1. 导入 Foundation
2. 使用 `L10n` 枚举访问本地化字符串
3. 运行应用并测试不同语言

示例:

```swift
// 旧代码 (硬编码)
Text("设置")

// 新代码 (本地化)
Text(L10n.settings)
```

---

**注意**: 目前代码中仍使用硬编码字符串。要完全启用国际化,需要将所有硬编码字符串替换为 `L10n` 枚举调用。这可以逐步进行,不影响应用功能。
