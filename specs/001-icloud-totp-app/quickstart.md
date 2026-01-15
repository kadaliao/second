# Quickstart: iCloud-Synced 2FA (TOTP) Application

**Feature**: 001-icloud-totp-app
**Branch**: `001-icloud-totp-app`
**Last Updated**: 2026-01-15

## Overview

This guide helps developers quickly understand the TOTP app architecture, set up the development environment, and start contributing.

## Project Structure

```
Second/                              # iOS app target
├── App/                             # App lifecycle
├── Views/                           # SwiftUI views (screens + components)
├── ViewModels/                      # MVVM view models (business logic)
├── Models/                          # Data entities (Token, Vault, etc.)
├── Services/                        # External integrations (Keychain, iCloud, crypto)
└── Utilities/                       # Shared helpers (logging, clipboard)

SecondTests/                         # Test target
├── Unit/                            # Pure logic tests (TOTP, encryption, Base32)
├── Integration/                     # System boundary tests (Keychain, iCloud)
└── Contract/                        # Data format tests (JSON schemas)
```

## Architecture Overview

### MVVM Pattern

```
User Interaction
      ↓
SwiftUI View ← (Binding) → ViewModel ← (ObservableObject) → Service Layer
                                            ↓
                                    Models (Token, Vault)
                                            ↓
                                    External Systems (Keychain, iCloud, CryptoKit)
```

**Key Components**:

1. **Views** (SwiftUI):
   - Declarative UI
   - Observe ViewModels via `@StateObject`, `@ObservedObject`
   - Zero business logic (display only)

2. **ViewModels** (`ObservableObject`):
   - Manage state (`@Published` properties)
   - Handle user actions (button taps, text input)
   - Coordinate between Views and Services
   - Example: `TokenListViewModel` manages token list, search, clipboard

3. **Services**:
   - Encapsulate external dependencies
   - Provide async/await APIs
   - Example: `EncryptionService.encrypt(vault:) async throws -> Data`

4. **Models**:
   - Plain Swift structs (value types)
   - `Codable` for JSON serialization
   - Validation logic embedded

---

## Key Technologies

| Technology | Purpose | Usage |
|------------|---------|-------|
| **SwiftUI** | UI framework | All views (TokenListView, AddTokenView, etc.) |
| **CryptoKit** | Encryption | AES-GCM vault encryption, HMAC for TOTP |
| **Keychain** | Secure storage | Vault key storage with iCloud sync |
| **NSUbiquitousKeyValueStore** | iCloud sync | Encrypted vault sync across devices |
| **AVFoundation** | Camera | QR code scanning (AVCaptureSession) |
| **XCTest** | Testing | Unit, integration, contract tests |
| **async/await** | Concurrency | All async operations (no completion handlers) |

---

## Data Flow Examples

### 1. App Launch → Display Tokens

```
App Launch (SecondApp.swift)
  ↓
TokenListView appears
  ↓
TokenListViewModel.onAppear()
  ↓
KeychainService.loadVaultKey() async
  ↓
iCloudSyncService.loadEncryptedVault() async
  ↓
EncryptionService.decrypt(encryptedVault, key) async
  ↓
Vault deserialized from JSON
  ↓
ViewModel.tokens = vault.tokens
  ↓
SwiftUI View updates (@Published triggers)
  ↓
User sees token list
```

---

### 2. User Adds Token via QR Code

```
User taps "+" button
  ↓
AddTokenView presented
  ↓
User selects "Scan QR Code"
  ↓
QRCodeScannerView (AVFoundation)
  ↓
QR code detected → otpauth:// URI
  ↓
QRCodeParser.parse(uri) throws
  ↓
Token created (validated)
  ↓
AddTokenViewModel.addToken(token)
  ↓
Vault.addToken(token) (in-memory)
  ↓
EncryptionService.encrypt(vault, key) async
  ↓
iCloudSyncService.saveEncryptedVault(encrypted) async
  ↓
NSUbiquitousKeyValueStore.set(data, forKey: "vault")
  ↓
iCloud syncs to other devices (automatic)
  ↓
AddTokenView dismissed
  ↓
TokenListView refreshes (shows new token)
```

---

### 3. TOTP Code Generation (Real-Time)

```
TokenCardView appears
  ↓
Timer publisher fires (every 1 second)
  ↓
TOTPGenerator.generate(token, currentTime) -> String
  ↓
Calculate timeRemaining = period - (currentTime % period)
  ↓
Update UI:
  - Display TOTP code ("123 456")
  - Update countdown timer (circle progress)
  - Change color to red if timeRemaining ≤ 5
  ↓
User taps card
  ↓
ClipboardHelper.copy(code)
  ↓
Toast notification: "Copied to clipboard"
```

---

### 4. Cross-Device Sync (Device B receives change)

```
Device A: User deletes token
  ↓
Vault updated, encrypted, saved to iCloud
  ↓
iCloud propagates change (5-10 seconds)
  ↓
Device B: NSUbiquitousKeyValueStore.didChangeExternallyNotification
  ↓
iCloudSyncService observes notification
  ↓
iCloudSyncService.loadEncryptedVault() async
  ↓
EncryptionService.decrypt(encryptedVault, key) async
  ↓
TokenListViewModel.vault = decryptedVault
  ↓
SwiftUI View auto-updates (@Published)
  ↓
Device B shows updated token list (deleted token removed)
```

---

## Development Setup

### Prerequisites

- macOS 13.0+ (Ventura or later)
- Xcode 15.0+ (Swift 5.9+)
- Apple Developer Account (for device testing and iCloud entitlements)
- iOS 16+ device or simulator (Keychain sync requires physical device)

### Initial Setup

1. **Clone Repository**:
   ```bash
   git clone <repository-url>
   cd second
   git checkout 001-icloud-totp-app
   ```

2. **Open Xcode**:
   ```bash
   open Second.xcodeproj
   ```

3. **Configure Signing**:
   - Select "Second" target
   - Signing & Capabilities → Team → Select your Apple Developer team
   - Enable iCloud capability:
     - Key-Value Storage (NSUbiquitousKeyValueStore)
     - iCloud Keychain sync (automatic with Keychain)

4. **Add Entitlements** (if not auto-generated):
   - iCloud Key-Value Store:
     ```xml
     <key>com.apple.developer.ubiquity-kvstore-identifier</key>
     <string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
     ```

5. **Update Info.plist**:
   - Add camera usage description:
     ```xml
     <key>NSCameraUsageDescription</key>
     <string>需要使用相机扫描二维码以添加验证码</string>
     ```

6. **Build and Run**:
   - Cmd+R to build and run on simulator or device
   - Note: iCloud Keychain sync only works on physical devices signed into iCloud

---

## Testing Strategy

### Unit Tests (Fast, Isolated)

**Location**: `SecondTests/Unit/`

**Focus**: Pure logic, no dependencies

**Examples**:
- `TOTPGeneratorTests`: RFC 6238 test vectors
- `Base32DecoderTests`: RFC 4648 test vectors
- `EncryptionServiceTests`: Encrypt/decrypt round-trip
- `TokenTests`: Codable, validation

**Run**:
```bash
# All unit tests
xcodebuild test -scheme Second -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SecondTests/Unit

# Single test file
xcodebuild test -scheme Second -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SecondTests/Unit/TOTPGeneratorTests
```

---

### Integration Tests (System Boundaries)

**Location**: `SecondTests/Integration/`

**Focus**: External systems (Keychain, iCloud, file I/O)

**Examples**:
- `KeychainServiceTests`: Save/load vault key
- `iCloudSyncTests`: Mock KVStore read/write
- `VaultIntegrationTests`: End-to-end encrypt → save → load → decrypt

**Run**:
```bash
# All integration tests
xcodebuild test -scheme Second -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SecondTests/Integration

# Keychain tests (requires device)
xcodebuild test -scheme Second -destination 'platform=iOS,name=<Device Name>' -only-testing:SecondTests/Integration/KeychainServiceTests
```

**Note**: Keychain sync tests must run on physical devices (simulator Keychain is local-only).

---

### Contract Tests (Data Formats)

**Location**: `SecondTests/Contract/`

**Focus**: JSON schemas, URI parsing compliance

**Examples**:
- `TokenSchemaTests`: JSON encoding matches `contracts/token-schema.json`
- `VaultFormatTests`: Encrypted format structure
- `OTPAuthURITests`: otpauth:// URI parsing (valid/invalid cases)

**Run**:
```bash
# All contract tests
xcodebuild test -scheme Second -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SecondTests/Contract
```

---

## TDD Workflow

Following Constitution Principle I (Test-First Development):

### Red-Green-Refactor

1. **Red**: Write failing test
   ```swift
   func testGenerateTOTPWithSHA1() {
       let token = Token(issuer: "Test", account: "test", secret: "JBSWY3DPEHPK3PXP")
       let totp = TOTPGenerator.generate(token: token, time: Date(timeIntervalSince1970: 59))
       XCTAssertEqual(totp, "94287082") // RFC 6238 test vector
   }
   ```

2. **Green**: Implement minimal code to pass
   ```swift
   struct TOTPGenerator {
       static func generate(token: Token, time: Date) -> String {
           // Implement TOTP logic
       }
   }
   ```

3. **Refactor**: Clean up while keeping tests green
   ```swift
   struct TOTPGenerator {
       static func generate(token: Token, time: Date = Date()) -> String {
           // Refactored implementation
       }
   }
   ```

---

## Common Development Tasks

### Add a New Service

1. Create file: `Second/Services/MyService.swift`
2. Define protocol:
   ```swift
   protocol MyServiceProtocol {
       func doSomething() async throws -> Result
   }
   ```
3. Implement:
   ```swift
   class MyService: MyServiceProtocol {
       func doSomething() async throws -> Result {
           // Implementation
       }
   }
   ```
4. Write tests first: `SecondTests/Unit/MyServiceTests.swift`
5. Use in ViewModel:
   ```swift
   class MyViewModel: ObservableObject {
       private let myService: MyServiceProtocol
       init(myService: MyServiceProtocol = MyService()) {
           self.myService = myService
       }
   }
   ```

---

### Add a New View

1. Create file: `Second/Views/MyView.swift`
2. Define SwiftUI view:
   ```swift
   struct MyView: View {
       @StateObject private var viewModel = MyViewModel()

       var body: some View {
           // UI code
       }
   }
   ```
3. Add to navigation:
   ```swift
   NavigationLink("Go to MyView") {
       MyView()
   }
   ```
4. Test manually (UI tests optional for this project)

---

### Add a New Model

1. Create file: `Second/Models/MyModel.swift`
2. Define struct:
   ```swift
   struct MyModel: Codable, Identifiable {
       let id: UUID
       var name: String
   }
   ```
3. Add validation:
   ```swift
   extension MyModel {
       func validate() throws {
           guard !name.isEmpty else {
               throw ValidationError.emptyName
           }
       }
   }
   ```
4. Write contract test: `SecondTests/Contract/MyModelTests.swift`

---

## Debugging Tips

### Keychain Issues

**Problem**: Keychain key not syncing across devices

**Solutions**:
- Verify iCloud Keychain enabled: Settings → Apple ID → iCloud → Keychain → ON
- Check entitlements: `com.apple.developer.ubiquity-kvstore-identifier` present
- Test on physical devices (not simulator)
- Wait 30 seconds after saving key for sync propagation

---

### iCloud Sync Issues

**Problem**: Vault not syncing across devices

**Solutions**:
- Verify iCloud enabled: Settings → Apple ID → iCloud → ON
- Check NSUbiquitousKeyValueStore limit (1MB max)
- Observe notification:
  ```swift
  NotificationCenter.default.addObserver(
      forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
      object: NSUbiquitousKeyValueStore.default,
      queue: .main
  ) { notification in
      print("iCloud change detected: \(notification)")
  }
  ```
- Call `NSUbiquitousKeyValueStore.default.synchronize()` after writes

---

### TOTP Code Incorrect

**Problem**: Generated TOTP codes don't match expected values

**Solutions**:
- Verify system time is accurate (TOTP requires accurate clock)
- Check secret is correctly Base32 decoded
- Verify algorithm matches service (SHA1 vs SHA256 vs SHA512)
- Test with RFC 6238 Appendix B test vectors first

---

### Encryption/Decryption Errors

**Problem**: `CryptoKitError.authenticationFailure` when decrypting vault

**Solutions**:
- Verify vault key is correct (not regenerated)
- Check ciphertext not corrupted (integrity check failed)
- Ensure nonce uniqueness (CryptoKit handles automatically)
- Test round-trip: plaintext → encrypt → decrypt → verify match

---

## Resources

### Documentation

- **Feature Spec**: `specs/001-icloud-totp-app/spec.md`
- **Implementation Plan**: `specs/001-icloud-totp-app/plan.md`
- **Research**: `specs/001-icloud-totp-app/research.md`
- **Data Model**: `specs/001-icloud-totp-app/data-model.md`
- **Contracts**: `specs/001-icloud-totp-app/contracts/`

### External References

- [RFC 6238 (TOTP)](https://datatracker.ietf.org/doc/html/rfc6238)
- [RFC 4226 (HOTP)](https://datatracker.ietf.org/doc/html/rfc4226)
- [RFC 4648 (Base32)](https://datatracker.ietf.org/doc/html/rfc4648)
- [Google Authenticator Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format)
- [Apple CryptoKit Documentation](https://developer.apple.com/documentation/cryptokit)
- [NSUbiquitousKeyValueStore Documentation](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore)
- [Keychain Services Documentation](https://developer.apple.com/documentation/security/keychain_services)

### Apple Developer

- [iCloud Key-Value Storage Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForKey-ValueDataIniCloud.html)
- [Keychain Services Programming Guide](https://developer.apple.com/documentation/security/keychain_services)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

---

## Next Steps

1. **Read Feature Spec**: Understand user stories and requirements
2. **Review Data Model**: Understand entities and relationships
3. **Explore Codebase**: Browse Views, ViewModels, Services
4. **Run Tests**: `Cmd+U` to run all tests, verify setup
5. **Start Contributing**: Pick a task from `tasks.md` (generated by `/speckit.tasks`)

---

## Questions?

- Check `specs/001-icloud-totp-app/research.md` for technical decisions
- Review `specs/001-icloud-totp-app/data-model.md` for entity details
- Read `.specify/memory/constitution.md` for project principles
- Ask in team chat or create GitHub issue

---

**Quickstart Status**: ✅ COMPLETE
**Version**: 1.0.0
**Last Updated**: 2026-01-15
