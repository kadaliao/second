# Data Model: iCloud-Synced 2FA (TOTP) Application

**Feature**: 001-icloud-totp-app
**Date**: 2026-01-15
**Status**: Phase 1 Design

## Overview

This document defines the data entities, relationships, validation rules, and state transitions for the TOTP application. All models are designed for Swift Codable serialization and encryption.

## Entity Definitions

### 1. Token

Represents a single 2FA account entry with TOTP parameters.

**Purpose**: Store all information needed to generate TOTP codes for a specific account.

**Attributes**:

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| `id` | UUID | Yes | Auto-generated | Unique identifier for the token |
| `issuer` | String | Yes | 1-100 chars, non-empty after trim | Service name (e.g., "GitHub", "Google") |
| `account` | String | Yes | 1-200 chars, non-empty after trim | Username or email (e.g., "user@example.com") |
| `secret` | String | Yes | Valid Base32, 16+ chars | Base32-encoded shared secret (stored encrypted) |
| `digits` | Int | Yes | 6 or 8 | Number of digits in TOTP code |
| `period` | Int | Yes | 15, 30, 60 (most common) | Time step in seconds (default: 30) |
| `algorithm` | TOTPAlgorithm | Yes | .sha1, .sha256, .sha512 | HMAC algorithm (default: .sha1) |
| `createdAt` | Date | Yes | Auto-generated | Timestamp of token creation |
| `updatedAt` | Date | Yes | Auto-updated | Timestamp of last modification |

**Swift Definition**:
```swift
struct Token: Identifiable, Codable, Equatable {
    let id: UUID
    var issuer: String
    var account: String
    let secret: String // Base32-encoded, never modified after creation
    var digits: Int
    var period: Int
    var algorithm: TOTPAlgorithm
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         issuer: String,
         account: String,
         secret: String,
         digits: Int = 6,
         period: Int = 30,
         algorithm: TOTPAlgorithm = .sha1) {
        self.id = id
        self.issuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        self.account = account.trimmingCharacters(in: .whitespacesAndNewlines)
        self.secret = secret
        self.digits = digits
        self.period = period
        self.algorithm = algorithm
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

**Validation Rules**:
- `issuer`: Non-empty after trimming whitespace (FR-005)
- `account`: Non-empty after trimming whitespace (FR-005)
- `secret`: Must be valid Base32 (A-Z, 2-7, optional padding '=') (FR-006)
- `digits`: Must be 6 or 8 (FR-002, FR-003)
- `period`: Must be positive integer (typically 15, 30, or 60) (FR-002, FR-003)
- `algorithm`: Must be one of sha1, sha256, sha512 (FR-002, FR-003)

**State Transitions**:
- **Create**: User scans QR code or manually enters data → Token created with auto-generated ID and timestamps
- **Update**: User edits issuer or account → `updatedAt` timestamp updated (secret, digits, period, algorithm immutable)
- **Delete**: User confirms deletion → Token removed from vault

**Relationships**:
- Belongs to: `Vault` (contained within encrypted vault)

---

### 2. TOTPAlgorithm

Enumeration of supported HMAC algorithms for TOTP generation.

**Purpose**: Type-safe representation of TOTP algorithm parameter.

**Swift Definition**:
```swift
enum TOTPAlgorithm: String, Codable, CaseIterable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"

    var cryptoKitAlgorithm: Any {
        switch self {
        case .sha1: return Insecure.SHA1.self
        case .sha256: return SHA256.self
        case .sha512: return SHA512.self
        }
    }
}
```

**Validation**:
- Must be one of the three enum cases
- String representation matches otpauth:// URI standard (uppercase)

---

### 3. Vault

Encrypted container for all tokens. Represents the entire user dataset stored in iCloud.

**Purpose**: Group all tokens for batch encryption/decryption and versioning.

**Attributes**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tokens` | [Token] | Yes | Array of all user tokens (may be empty) |
| `version` | Int | Yes | Schema version for migration compatibility (current: 1) |
| `lastModified` | Date | Yes | Timestamp of last vault modification |

**Swift Definition**:
```swift
struct Vault: Codable {
    var tokens: [Token]
    let version: Int
    var lastModified: Date

    init(tokens: [Token] = [], version: Int = 1) {
        self.tokens = tokens
        self.version = version
        self.lastModified = Date()
    }

    mutating func addToken(_ token: Token) {
        tokens.append(token)
        lastModified = Date()
    }

    mutating func updateToken(_ token: Token) {
        if let index = tokens.firstIndex(where: { $0.id == token.id }) {
            var updatedToken = token
            updatedToken.updatedAt = Date()
            tokens[index] = updatedToken
            lastModified = Date()
        }
    }

    mutating func deleteToken(id: UUID) {
        tokens.removeAll(where: { $0.id == id })
        lastModified = Date()
    }
}
```

**Serialization**:
1. Vault → JSON (via `JSONEncoder`)
2. JSON → Data
3. Data → Encrypted (AES-GCM via `EncryptionService`)
4. Encrypted Data → iCloud (via `NSUbiquitousKeyValueStore`)

**Validation Rules**:
- `version`: Must be positive integer (current: 1)
- `tokens`: May be empty array (valid state for new users)

**State Transitions**:
- **Empty**: New user, no tokens → `tokens = []`
- **Populated**: User adds tokens → `tokens.count > 0`
- **Modified**: User adds/updates/deletes token → `lastModified` updated

---

### 4. EncryptedVault

Wrapper for encrypted vault data stored in iCloud.

**Purpose**: Represent encrypted blob with metadata for transmission and storage.

**Attributes**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ciphertext` | Data | Yes | AES-GCM SealedBox.combined (nonce + ciphertext + tag) |
| `encryptionAlgorithm` | String | Yes | "AES-GCM-256" (for future compatibility) |

**Swift Definition**:
```swift
struct EncryptedVault {
    let ciphertext: Data // AES.GCM.SealedBox.combined
    let encryptionAlgorithm: String // "AES-GCM-256"

    init(ciphertext: Data) {
        self.ciphertext = ciphertext
        self.encryptionAlgorithm = "AES-GCM-256"
    }
}
```

**Storage Format** (in NSUbiquitousKeyValueStore):
- Key: `"vault"`
- Value: `ciphertext` (Data) - stored as-is, no additional encoding

**Validation**:
- `ciphertext`: Must be non-empty Data
- `encryptionAlgorithm`: Must be "AES-GCM-256" (for version 1)

---

### 5. VaultKey

Encryption/decryption key for the vault, stored in Keychain.

**Purpose**: Symmetric key for AES-GCM encryption, synchronized via iCloud Keychain.

**Attributes**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `keyData` | Data | Yes | 256-bit (32 bytes) random key |
| `identifier` | String | Yes | "vaultKey" (Keychain account identifier) |

**Swift Definition**:
```swift
// Not a struct, but represented as CryptoKit SymmetricKey
// Stored in Keychain, never serialized to disk or iCloud

// Generation
let key = SymmetricKey(size: .bits256) // 32 bytes

// Keychain attributes
let keychainQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "vaultKey",
    kSecAttrService as String: "com.second.totp",
    kSecValueData as String: keyData,
    kSecAttrSynchronizable as String: true,
    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
]
```

**Validation**:
- `keyData`: Must be exactly 32 bytes (256 bits)
- Generated once on first launch, never regenerated (regeneration would make existing vaults unreadable)

**Lifecycle**:
- **Generate**: First app launch → generate key, save to Keychain
- **Retrieve**: Subsequent launches → load key from Keychain
- **Sync**: Keychain automatically syncs to other devices via iCloud Keychain
- **Missing**: If key not found but encrypted vault exists → error state (FR-022, FR-023)

---

## Entity Relationships

```
Vault (1) ──┬──> (0..*) Token
            │
            └──> VaultKey (encryption)
                    │
                    └──> EncryptedVault (iCloud)
```

**Description**:
- One `Vault` contains zero or more `Token` entities
- `Vault` is encrypted using `VaultKey` to produce `EncryptedVault`
- `EncryptedVault` is stored in NSUbiquitousKeyValueStore (iCloud)
- `VaultKey` is stored in Keychain (synchronized via iCloud Keychain)

---

## Data Flow

### 1. Token Creation (FR-004, FR-005)

```
User Input (QR or Manual)
  ↓
QRCodeParser / Manual Entry
  ↓
Validate (Base32 secret, issuer, account)
  ↓
Create Token (auto-generate ID, timestamps)
  ↓
Add to Vault (in-memory)
  ↓
Serialize Vault → JSON → Data
  ↓
Encrypt Data → EncryptedVault (AES-GCM)
  ↓
Save to iCloud (NSUbiquitousKeyValueStore)
```

### 2. Token Retrieval (App Launch)

```
App Launch
  ↓
Load VaultKey from Keychain
  ↓
Load EncryptedVault from iCloud
  ↓
Decrypt EncryptedVault → Data
  ↓
Deserialize Data → JSON → Vault
  ↓
Load Tokens into ViewModel (in-memory)
  ↓
Display Token List
```

### 3. TOTP Generation (FR-007, FR-008)

```
Timer Tick (every 1 second)
  ↓
For each Token:
  ↓
  Calculate T = (Current Time - T0) / Period
  ↓
  Generate HMAC(Secret, T) using Algorithm
  ↓
  Truncate HMAC → OTP (Digits)
  ↓
  Format OTP → Display (e.g., "123 456")
```

### 4. Cross-Device Sync (FR-020)

```
Device A: User modifies Vault
  ↓
Encrypt → Save to iCloud (NSUbiquitousKeyValueStore)
  ↓
iCloud propagates change (5-10 seconds)
  ↓
Device B: Receive NSUbiquitousKeyValueStore.didChangeExternallyNotification
  ↓
Load EncryptedVault from iCloud
  ↓
Decrypt using VaultKey from Keychain
  ↓
Update in-memory Vault
  ↓
Refresh UI
```

---

## Validation Summary

### Token Validation

```swift
extension Token {
    enum ValidationError: Error {
        case emptyIssuer
        case emptyAccount
        case invalidSecret // Not valid Base32
        case invalidDigits // Not 6 or 8
        case invalidPeriod // Not positive
    }

    func validate() throws {
        guard !issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyIssuer
        }
        guard !account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyAccount
        }
        guard Base32Decoder.isValid(secret) else {
            throw ValidationError.invalidSecret
        }
        guard digits == 6 || digits == 8 else {
            throw ValidationError.invalidDigits
        }
        guard period > 0 else {
            throw ValidationError.invalidPeriod
        }
    }
}
```

### Vault Validation

```swift
extension Vault {
    enum ValidationError: Error {
        case invalidVersion
        case duplicateTokenIDs
    }

    func validate() throws {
        guard version > 0 else {
            throw ValidationError.invalidVersion
        }
        let ids = tokens.map { $0.id }
        guard ids.count == Set(ids).count else {
            throw ValidationError.duplicateTokenIDs
        }
    }
}
```

---

## Migration Strategy

**Current Version**: 1

**Future Migrations**:
- If schema changes (e.g., add new Token field), increment `Vault.version`
- On decrypt, check version and apply migration if needed
- Example migration pseudocode:
```swift
func migrate(vault: Vault, from oldVersion: Int, to newVersion: Int) -> Vault {
    var migratedVault = vault
    if oldVersion == 1 && newVersion == 2 {
        // Apply migration logic
        migratedVault.tokens = vault.tokens.map { token in
            // Add default value for new field
        }
        migratedVault.version = 2
    }
    return migratedVault
}
```

**Migration Constraints**:
- Must maintain backward compatibility (newer app versions can read older vaults)
- Never delete fields (mark as deprecated, provide defaults)
- Always test migrations with real user data (exported vaults)

---

## Security Considerations

### Sensitive Data

**Never Logged / Displayed in Plain Text**:
- `Token.secret` (Base32 secret key)
- `VaultKey.keyData` (AES-GCM key)
- Decrypted `Vault` JSON
- Generated TOTP codes (only displayed in UI, never logged)

**Encrypted at Rest**:
- All tokens in `Vault` (encrypted via AES-GCM before iCloud storage)

**Secure Storage**:
- `VaultKey`: Stored in Keychain with hardware-backed encryption
- `EncryptedVault`: Stored in iCloud (ciphertext only, no keys)

### Data Lifecycle

1. **In Use** (App Running):
   - Vault decrypted in memory
   - Tokens accessible for TOTP generation
   - VaultKey loaded from Keychain

2. **At Rest** (App Closed):
   - Vault encrypted in iCloud
   - VaultKey encrypted in Keychain
   - No plaintext data on disk

3. **In Transit** (Sync):
   - EncryptedVault transmitted via iCloud (Apple-managed TLS)
   - VaultKey transmitted via iCloud Keychain (encrypted, Apple-managed)

---

## Testing Strategy

### Unit Tests (Models)

1. **Token**:
   - Test Codable serialization/deserialization
   - Test validation rules (empty issuer, invalid secret, invalid digits)
   - Test state transitions (create, update)

2. **Vault**:
   - Test addToken / updateToken / deleteToken
   - Test Codable with empty and populated token arrays
   - Test validation (duplicate IDs)

3. **TOTPAlgorithm**:
   - Test Codable (string representation)
   - Test all enum cases map correctly to CryptoKit algorithms

### Integration Tests (Encryption + Storage)

1. **Vault Encryption**:
   - Encrypt Vault → EncryptedVault
   - Decrypt EncryptedVault → Vault
   - Verify round-trip (plaintext → encrypted → plaintext)

2. **Keychain Integration**:
   - Save VaultKey to Keychain
   - Retrieve VaultKey from Keychain
   - Verify key persistence across app restarts (on device)

3. **iCloud Sync** (Mock):
   - Save EncryptedVault to mock KVStore
   - Trigger external change notification
   - Verify vault reloaded and decrypted

### Contract Tests

1. **Token Schema**:
   - Test JSON encoding matches expected schema (see contracts/token-schema.json)
   - Test backward compatibility (add new optional field, ensure old apps can decode)

2. **Vault Format**:
   - Test encrypted format structure (see contracts/vault-format.json)
   - Test version field persistence

3. **otpauth:// URI**:
   - Test parsing all valid URI formats (see contracts/otpauth-uri-spec.md)
   - Test edge cases (missing issuer, custom parameters)

---

**Phase 1 Data Model Status**: ✅ COMPLETE
**Next**: Generate contracts/ (token-schema.json, vault-format.json, otpauth-uri-spec.md)
