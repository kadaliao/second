# Second 国际化实现

## ✅ 已完成

Second 应用现已支持国际化,提供中文简体和英文两种语言。

### 核心文件

1. **Localizable.xcstrings** ([`Second/Resources/Localizable.xcstrings`](../Second/Resources/Localizable.xcstrings))
   - 68 个本地化字符串
   - 支持中文简体 (zh-Hans) 和英文 (en)
   - 使用 String Catalog 格式 (Xcode 15+)

2. **LocalizableStrings.swift** ([`Second/Utilities/LocalizableStrings.swift`](../Second/Utilities/LocalizableStrings.swift))
   - `L10n` 枚举提供类型安全的本地化键
   - 避免拼写错误,提供代码自动完成

3. **String+Localized.swift** ([`Second/Utilities/String+Localized.swift`](../Second/Utilities/String+Localized.swift))
   - String 扩展,提供 `.localized` 方法

## 使用示例

### 推荐方式: 使用 L10n 枚举

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        VStack {
            // 简单字符串
            Text(L10n.settings)
            Text(L10n.loading)
            
            // 带参数的字符串
            Text(L10n.syncedAt("2分钟前"))
        }
    }
}
```

## 测试方法

### 方法 1: 在模拟器中测试

1. 打开模拟器的 **设置** → **通用** → **语言与地区**
2. 添加或切换语言为 **English**
3. 重启 Second 应用

### 方法 2: 在 Xcode 中测试

1. **Product** → **Scheme** → **Edit Scheme**
2. **Run** → **Options** → **App Language** → **English**
3. 运行应用

## 本地化覆盖范围

✅ 所有 UI 文本已本地化:
- 主界面 (TokenListView)
- 添加令牌 (AddTokenView)
- 编辑令牌 (EditTokenView)
- 设置 (SettingsView)
- 账号排序 (TokenSortView)
- iCloud 导出 (iCloudExportView)
- 错误状态 (ErrorStateView)
- 空状态 (EmptyStateView)
- ViewModel 消息

## 添加新字符串

### 步骤 1: 在 Localizable.xcstrings 中添加

```json
{
  "新字符串" : {
    "extractionState" : "manual",
    "localizations" : {
      "en" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "New String"
        }
      },
      "zh-Hans" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "新字符串"
        }
      }
    }
  }
}
```

### 步骤 2: 在 LocalizableStrings.swift 中添加

```swift
enum L10n {
    // ...
    static var newString: String { NSLocalizedString("新字符串", comment: "") }
}
```

### 步骤 3: 使用

```swift
Text(L10n.newString)
```

## 扩展到更多语言

要添加新语言(如日语):

1. 在 Localizable.xcstrings 的每个条目中添加新语言翻译
2. 在 Xcode Project Settings → Info → Localizations 中添加新语言

## 文件结构

```
Second/
├── Resources/
│   └── Localizable.xcstrings     # 本地化字符串
├── Utilities/
│   ├── LocalizableStrings.swift  # L10n 枚举
│   └── String+Localized.swift    # String 扩展
└── docs/
    └── README.md                  # 本文档
```

## 注意事项

- 源语言: 中文简体 (zh-Hans)
- 格式: String Catalog (.xcstrings, Xcode 15+)
- 当前代码仍使用硬编码字符串,需要逐步迁移到 L10n 枚举
- 所有本地化资源已就绪,可随时在代码中使用

## 相关资源

- [Apple Localization Guide](https://developer.apple.com/documentation/xcode/localization)
- [String Catalogs Documentation](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [NSLocalizedString Reference](https://developer.apple.com/documentation/foundation/nslocalizedstring)
