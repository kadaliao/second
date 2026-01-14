PRD：极简 iCloud 同步 2FA（TOTP）应用

1. 产品概述（What & Why）

产品定位

一款 纯 2FA（TOTP）验证码应用，强调：
• 极简、干净、审美在线
• 无账号系统
• 无自建服务器
• 依赖 Apple 生态完成同步与安全
• 开源、透明、可审计

目标是 Step Two 风格体验，而不是密码管理器。

⸻

2. 核心原则（不可破）
   1. 只做 TOTP
      • 不存网站密码
      • 不做通用密钥管理
      • 不做 Web 登录自动填充
   2. 无账号
      • 不注册
      • 不登录
      • 不收集身份信息
   3. 跨设备同步 = 同一个 Apple ID
      • 数据通过 iCloud 同步
      • 解密密钥通过 iCloud Keychain 同步
   4. 端到端加密
      • iCloud 上只存密文
      • App 本身无法在没有 Keychain 密钥的情况下解密数据

⸻

3. 用户使用路径（User Flow）

3.1 首次安装（任意设备）1. 用户打开 App 2. App 检查 Keychain：
• 若不存在 vault key → 生成一个随机密钥
• 将密钥保存到 可同步的 Keychain 3. 创建空 vault 4. UI 进入「空列表」状态

用户无感知，不需要任何设置。

⸻

3.2 添加一个 2FA

支持两种方式：
• 扫描二维码（otpauth://）
• 手动输入（issuer / account / secret）

添加后：
• 更新内存数据
• 使用 vault key 加密
• 写入 iCloud

⸻

3.3 跨设备同步（同 Apple ID）1. 新设备安装 App 2. iCloud 同步到加密数据 3. iCloud Keychain 同步到 vault key 4. 自动解密并显示

无需登录、无需确认、无需 FaceID。

⸻

4. 功能需求（Functional Requirements）

4.1 TOTP 支持
• RFC 6238
• 默认参数：
• digits = 6
• period = 30s
• algorithm = SHA1
• 支持常见变体（8 位 / SHA256 / SHA512）

⸻

4.2 数据模型（逻辑）

每个条目包含：
• issuer（服务名）
• account（邮箱 / 用户名）
• secret（base32，只在内存中明文存在）
• digits
• period
• algorithm
• created_at
• updated_at

⸻

4.3 UI（MVP）

主列表
• 卡片式列表
• 显示：
• issuer
• account（可选）
• 当前 TOTP
• 倒计时进度（环或条）
• 点击即可复制验证码

搜索
• 实时模糊搜索（issuer / account）

添加页
• 扫码
• 手动输入

编辑
• 修改 issuer / account
• 删除条目

⸻

5. 同步与存储设计（核心）

5.1 数据存储
• 单一 vault 文件
• 内容为 加密后的 JSON
• 存储位置：
• iCloud Drive 的 App 容器
或
• CloudKit 私有数据库（后续决定）

⸻

5.2 加密设计
• 算法：AES-GCM（CryptoKit）
• vault key：
• 随机生成
• 仅存 Keychain
• 标记为 synchronizable

iCloud 中 永远不存明文数据或密钥。

⸻

5.3 Keychain 使用原则
• vault key：
• 每个 Apple ID 唯一
• 自动跨设备同步（iCloud Keychain）
• App 不关心密钥如何同步，只负责：
• 读取
• 使用
• 判断是否存在

⸻

6. 异常与边界情况（必须写清楚）

6.1 iCloud 已同步，但 Keychain 未同步

可能原因：
• 用户关闭了 iCloud 钥匙串
• 企业设备 / MDM
• Apple ID 切换

处理方式：
• App 显示只读错误状态
• 提示：
“检测到你的验证码数据已从 iCloud 同步，但解密密钥不可用。请确认已开启 iCloud 钥匙串。”

不提供绕过方案。

⸻

6.2 用户丢失所有设备
• 如果 iCloud Keychain 不可恢复 → 数据不可解密
• App 不承诺数据找回
• 在 README / About 中明确说明

⸻

7. 非目标（明确不做）
   • ❌ 密码管理
   • ❌ Web 自动填充
   • ❌ 多平台（Android / Windows）
   • ❌ 自建云 / 后端
   • ❌ 社交 / 分享 / 团队功能
   • ❌ 强安全承诺营销用语

⸻

8. 开源与安全声明
   • 项目完全开源
   • 不做“军工级”“绝对安全”等承诺
   • 明确威胁模型：
   • 防 iCloud 数据泄露
   • 不防越狱设备
   • 不防设备被完全接管

⸻

9. MVP 成功标准（Definition of Done）
   • 同一 Apple ID：
   • iPhone 添加 2FA
   • Mac / iPad 自动同步并可用
   • iCloud 中数据为密文
   • 删除 App 再安装可恢复
   • UI 清爽，无多余引导

⸻

10. 产品一句话总结（给 README 用）

一个极简、无账号、依赖 Apple 生态的 2FA 应用。
数据加密后同步到 iCloud，解密密钥通过 iCloud Keychain 自动跨设备同步。
