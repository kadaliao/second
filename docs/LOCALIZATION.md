# Second - 国际化实现文档

## 概述

Second 应用已实现完整的国际化(i18n)支持,目前支持以下语言:
- 中文简体 (zh-Hans) - 默认语言
- 英文 (en)

## 文件结构

### 核心文件

- `Second/Resources/Localizable.xcstrings` - String Catalog 格式的本地化字符串文件,包含所有翻译
- `Second/Utilities/LocalizableStrings.swift` - 集中管理的本地化键定义 (L10n enum)
- `Second/Utilities/String+Localized.swift` - String 扩展,提供便捷的本地化方法

## 使用方法

### 方法 1: 使用 L10n 枚举(推荐)

这是最安全和推荐的方法,可以避免拼写错误并提供代码自动完成:

```swift
// 简单字符串
Text(L10n.settings)
Text(L10n.loading)

// 带参数的字符串
Text(L10n.syncedAt("2 分钟前"))
Text(L10n.confirmDeleteMessage(issuer: "GitHub", account: "user@example.com"))
```

### 方法 2: 使用 NSLocalizedString

直接使用 iOS 标准 API:

```swift
Text(NSLocalizedString("设置", comment: ""))
```

### 方法 3: 使用 String Extension

使用自定义扩展方法:

```swift
Text("设置".localized)
```

## 添加新的本地化字符串

### 步骤 1: 在 Localizable.xcstrings 中添加翻译

在 `Localizable.xcstrings` 文件中添加新的键值对:

```json
{
  "新的键" : {
    "extractionState" : "manual",
    "localizations" : {
      "en" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "New Key"
        }
      },
      "zh-Hans" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "新的键"
        }
      }
    }
  }
}
```

### 步骤 2: 在 LocalizableStrings.swift 中添加定义

在 `L10n` 枚举中添加对应的静态属性:

```swift
enum L10n {
    // ...existing code...

    static var newKey: String { NSLocalizedString("新的键", comment: "") }
}
```

### 步骤 3: 在代码中使用

```swift
Text(L10n.newKey)
```

## 带参数的字符串

对于需要动态参数的字符串:

### 在 Localizable.xcstrings 中定义

```json
{
  "欢迎, %@!" : {
    "extractionState" : "manual",
    "localizations" : {
      "en" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "Welcome, %@!"
        }
      },
      "zh-Hans" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "欢迎, %@!"
        }
      }
    }
  }
}
```

### 在 LocalizableStrings.swift 中定义

```swift
enum L10n {
    static func welcome(_ name: String) -> String {
        String(format: NSLocalizedString("欢迎, %@!", comment: ""), name)
    }
}
```

### 使用

```swift
Text(L10n.welcome("张三"))
```

## 测试

### 在模拟器中测试

1. 打开模拟器
2. 进入 **Settings** → **General** → **Language & Region**
3. 添加或切换语言
4. 重启应用查看效果

### 在 Xcode 中测试

1. 选择 **Product** → **Scheme** → **Edit Scheme**
2. 在 **Run** 选项卡的 **Options** 中
3. 设置 **App Language** 为想要测试的语言
4. 运行应用

## 最佳实践

1. **始终使用 L10n 枚举** - 提供类型安全和自动完成
2. **不要硬编码字符串** - 所有用户可见的文本都应本地化
3. **使用清晰的键名** - 键名应该是原始语言(中文简体),便于识别
4. **添加注释** - 在 NSLocalizedString 的 comment 参数中添加上下文说明
5. **测试所有语言** - 确保在所有支持的语言中测试 UI 和功能

## 当前本地化覆盖范围

✅ 已完成本地化的模块:

- UI 界面文本
- 错误消息
- 用户提示
- 表单标签和占位符
- 按钮文本
- 导航标题
- 设置项
- 空状态提示

## 支持的占位符格式

- `%@` - 字符串
- `%d` - 整数
- `%f` - 浮点数

示例:

```swift
// 一个参数
"你有 %d 个令牌"  // "You have %d tokens"

// 多个参数
"账号 %@ 已同步到 %d 台设备"  // "Account %@ synced to %d devices"
```

## 注意事项

1. **源语言设置** - 本项目源语言为中文简体 (zh-Hans)
2. **String Catalog** - 使用 Xcode 15+ 推荐的 .xcstrings 格式
3. **自动提取** - Xcode 可以自动提取项目中的 NSLocalizedString 调用
4. **版本控制** - Localizable.xcstrings 文件应纳入版本控制

## 扩展到更多语言

要添加新语言(例如日语):

1. 打开 Localizable.xcstrings 文件
2. 在每个字符串条目的 `localizations` 对象中添加新语言:

```json
{
  "设置" : {
    "extractionState" : "manual",
    "localizations" : {
      "en" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "Settings"
        }
      },
      "ja" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "設定"
        }
      },
      "zh-Hans" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "设置"
        }
      }
    }
  }
}
```

3. 在 Xcode Project Settings 中添加新语言到 Localizations 列表

## 参考资源

- [Apple Localization Guide](https://developer.apple.com/documentation/xcode/localization)
- [String Catalogs](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [NSLocalizedString](https://developer.apple.com/documentation/foundation/nslocalizedstring)
