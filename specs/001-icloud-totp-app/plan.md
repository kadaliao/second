# Implementation Plan: iCloud-Synced 2FA (TOTP) Application

**Branch**: `001-icloud-totp-app` | **Date**: 2026-01-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-icloud-totp-app/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a native iOS 2FA (TOTP) application that stores and syncs encrypted authentication tokens across Apple devices via iCloud, without requiring user accounts or backend servers. The app will use SwiftUI for UI, CryptoKit for AES-GCM encryption, Keychain for key storage, and iCloud for encrypted data sync.

## Technical Context

**Language/Version**: Swift 5.9+ (targeting iOS 16+)
**Primary Dependencies**: SwiftUI, CryptoKit, AVFoundation (QR scanning), CloudKit or NSUbiquitousKeyValueStore (NEEDS CLARIFICATION: which iCloud sync mechanism)
**Storage**: iCloud (encrypted vault), Keychain (vault key with kSecAttrSynchronizable=true), in-memory cache during session
**Testing**: XCTest (unit, integration, contract tests following TDD principles)
**Target Platform**: iOS 16+, iPadOS 16+ (Apple ecosystem only)
**Project Type**: Mobile (single iOS app)
**Performance Goals**: TOTP generation <50ms, vault decryption <200ms, search filtering <100ms, 60 fps UI
**Constraints**: No backend servers, no user accounts, no third-party SDKs (except SPM for minimal deps), iCloud-only sync, vault key never leaves Keychain, all iCloud data encrypted
**Scale/Scope**: Support up to 50 tokens per user, single-screen main view + add/edit modals, <1MB encrypted vault size

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development ✅ PASS

- **Status**: COMPLIANT
- **Plan**: All user stories in spec.md include Given-When-Then acceptance criteria. Implementation will follow strict Red-Green-Refactor cycle.
- **Test Coverage Plan**:
  - Unit tests: TOTP generation (RFC 6238), Base32 decoding, encryption/decryption, timer logic
  - Integration tests: Keychain access, iCloud sync operations, QR code parsing
  - Contract tests: Token data model, encrypted vault format, otpauth:// URI parsing
- **Actions**: Phase 0 will define test structure; tasks.md will order tests before implementation tasks

### II. Security-First Architecture ✅ PASS

- **Status**: COMPLIANT
- **Encryption**: AES-256-GCM via CryptoKit (native, audited by Apple)
- **Key Storage**: Keychain with `kSecAttrSynchronizable=true` for cross-device sync
- **Data at Rest**: Only encrypted ciphertext in iCloud; plaintext secrets never stored outside Keychain-protected memory
- **Network**: Zero network calls except iCloud APIs (Apple-controlled)
- **Threat Model**: Will be documented in research.md (Phase 0)
- **Review**: All crypto/Keychain/iCloud code will require peer review
- **Actions**: Phase 0 research will clarify CloudKit vs NSUbiquitousKeyValueStore security posture

### III. Apple Ecosystem Standards ✅ PASS

- **Status**: COMPLIANT
- **Language**: Swift (no Objective-C)
- **UI**: SwiftUI (declarative, testable)
- **Concurrency**: async/await (no completion handlers or Rx/Combine for core logic)
- **Cryptography**: CryptoKit only (no OpenSSL, CommonCrypto, or third-party crypto)
- **Sync**: iCloud (CloudKit or NSUbiquitousKeyValueStore - to be decided in Phase 0)
- **Testing**: XCTest (no third-party test frameworks)
- **Dependencies**: SPM for package management; minimize external deps
- **Actions**: Phase 0 will research CloudKit vs NSUbiquitousKeyValueStore and document best practices

### IV. Simplicity and Minimalism ✅ PASS

- **Status**: COMPLIANT
- **Scope**: TOTP only (RFC 6238) - no passwords, passkeys, or other credential types
- **No Account System**: Relies on Apple ID (FR-024, FR-025)
- **No Backend**: iCloud-only sync (FR-026)
- **No Analytics**: Zero telemetry (FR-025)
- **UI Simplicity**: Single main screen (token list + search) + modals (add/edit)
- **Feature Discipline**: All requirements in spec.md align with "one thing well" principle
- **Actions**: No complexity justification needed

### V. Observability and Debuggability ✅ PASS

- **Status**: COMPLIANT
- **Logging Plan**: Structured logging for Keychain access, encryption/decryption, iCloud sync events
- **Log Levels**: ERROR, WARNING, INFO, DEBUG
- **Security**: No secrets, keys, or plaintext TOTP codes in logs (will enforce via code review)
- **User-Facing Errors**: Clear guidance when sync fails or Keychain unavailable (FR-022, FR-023)
- **Performance Instrumentation**: Will measure encryption (<200ms), TOTP generation (<50ms)
- **Actions**: Phase 1 will define error state UI flows and logging structure

### Gate Summary

**Result**: ✅ ALL GATES PASS

- No violations requiring justification
- One clarification needed: CloudKit vs NSUbiquitousKeyValueStore (Phase 0 research)
- All five constitution principles aligned with feature requirements
- No complexity additions beyond spec.md requirements

**Proceed to Phase 0**: Research approved

## Project Structure

### Documentation (this feature)

```text
specs/001-icloud-totp-app/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── token-schema.json          # Token entity contract
│   ├── vault-format.json          # Encrypted vault format contract
│   └── otpauth-uri-spec.md        # otpauth:// URI parsing contract
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
Second/                              # iOS app target
├── App/
│   ├── SecondApp.swift             # App entry point (@main)
│   └── AppDelegate.swift           # Lifecycle, iCloud setup
├── Views/
│   ├── TokenListView.swift         # Main screen (token cards + search)
│   ├── AddTokenView.swift          # Modal for QR scan or manual entry
│   ├── EditTokenView.swift         # Modal for editing issuer/account
│   ├── ErrorStateView.swift        # Keychain unavailable error screen
│   └── Components/
│       ├── TokenCardView.swift     # Individual token card with TOTP + timer
│       ├── CountdownTimerView.swift# Circular progress timer
│       └── EmptyStateView.swift    # "Tap + to add" guidance
├── ViewModels/
│   ├── TokenListViewModel.swift    # Manages token list, search, clipboard
│   ├── AddTokenViewModel.swift     # QR scan, manual entry validation
│   └── SyncViewModel.swift         # iCloud sync status
├── Models/
│   ├── Token.swift                 # Token entity (issuer, account, secret, params)
│   ├── Vault.swift                 # Encrypted vault wrapper
│   └── TOTPParameters.swift        # TOTP config (digits, period, algorithm)
├── Services/
│   ├── TOTPGenerator.swift         # RFC 6238 implementation
│   ├── EncryptionService.swift     # AES-GCM encryption/decryption via CryptoKit
│   ├── KeychainService.swift       # Vault key storage/retrieval
│   ├── iCloudSyncService.swift     # Encrypted vault sync (CloudKit or KVStore)
│   ├── QRCodeParser.swift          # otpauth:// URI parsing
│   └── Base32Decoder.swift         # Base32 secret decoding
└── Utilities/
    ├── Logger.swift                # Structured logging (no secrets)
    └── ClipboardHelper.swift       # Clipboard + toast notification

SecondTests/                         # Test target
├── Unit/
│   ├── TOTPGeneratorTests.swift    # RFC 6238 test vectors
│   ├── EncryptionServiceTests.swift# AES-GCM encrypt/decrypt
│   ├── Base32DecoderTests.swift    # Base32 edge cases
│   ├── QRCodeParserTests.swift     # otpauth:// URI parsing
│   └── TokenTests.swift            # Model validation
├── Integration/
│   ├── KeychainServiceTests.swift  # Keychain read/write/sync
│   ├── iCloudSyncTests.swift       # Mock iCloud sync operations
│   └── VaultIntegrationTests.swift # End-to-end encrypt → sync → decrypt
└── Contract/
    ├── TokenSchemaTests.swift      # Codable contract
    ├── VaultFormatTests.swift      # Encrypted format contract
    └── OTPAuthURITests.swift       # otpauth:// spec compliance

Resources/
├── Info.plist                       # iCloud entitlements, camera usage description
└── Assets.xcassets/                 # App icons, color sets (light/dark mode)
```

**Structure Decision**: Mobile (Option 3 variant) - Single iOS app target with MVVM architecture. SwiftUI views are organized by feature (list, add, edit, error), ViewModels handle business logic and state, Models define data entities, Services encapsulate external dependencies (Keychain, iCloud, encryption), and Utilities provide shared helpers. Tests mirror source structure with unit/integration/contract separation per TDD requirements.

## Complexity Tracking

> No violations - this section intentionally left empty per Constitution Check gate summary.

---

## Post-Design Constitution Re-Check

*Re-evaluated after Phase 1 design (data-model.md, contracts/, quickstart.md)*

### Design Artifacts Review

**Generated Artifacts**:
- `research.md`: Technology decisions (NSUbiquitousKeyValueStore, CryptoKit, custom Base32)
- `data-model.md`: Entities (Token, Vault, VaultKey, TOTPAlgorithm, EncryptedVault)
- `contracts/`: JSON schemas (token-schema.json, vault-format.json, otpauth-uri-spec.md)
- `quickstart.md`: Developer onboarding guide

### Constitution Compliance Re-Check

#### I. Test-First Development ✅ COMPLIANT

**Design Support**:
- Data model includes validation rules for all entities
- Contract tests defined in data-model.md (TokenSchemaTests, VaultFormatTests, OTPAuthURITests)
- Quickstart.md documents TDD workflow (Red-Green-Refactor)
- Test structure mirrors source structure (Unit, Integration, Contract)

**No Violations**: Design reinforces TDD requirement.

---

#### II. Security-First Architecture ✅ COMPLIANT

**Design Support**:
- Encryption: AES-GCM via CryptoKit (research.md confirms native, audited)
- Key Storage: Keychain with `kSecAttrSynchronizable=true` (data-model.md: VaultKey)
- Data at Rest: Only ciphertext in iCloud (data-model.md: EncryptedVault structure)
- Sensitive Data Protection: data-model.md explicitly lists "Never Logged" fields (Token.secret, VaultKey.keyData)
- Threat Model: Documented in research.md (protected against iCloud breach, device loss)

**No Violations**: All security requirements met in design.

---

#### III. Apple Ecosystem Standards ✅ COMPLIANT

**Design Support**:
- Swift only (no Objective-C) - confirmed in project structure
- SwiftUI for all views - confirmed in quickstart.md architecture
- async/await for concurrency - documented in data-model.md data flows
- CryptoKit for crypto - research.md confirms no third-party crypto libs
- NSUbiquitousKeyValueStore for sync - research.md decision rationale
- XCTest for testing - quickstart.md test strategy

**No Violations**: Design adheres to Apple standards.

---

#### IV. Simplicity and Minimalism ✅ COMPLIANT

**Design Support**:
- Scope: TOTP only (data-model.md: Token entity is pure TOTP, no password fields)
- No Account System: No user/auth entities in data model
- No Backend: iCloud-only sync (research.md confirms no custom backend)
- Minimal Dependencies: Custom Base32 decoder (research.md: zero external deps for Base32)
- Single-file vault: One encrypted blob in iCloud (data-model.md: Vault structure)

**Complexity Added**:
- Custom Base32 decoder (~80 lines) - JUSTIFIED: Zero dependencies, simple algorithm, fully testable
- Encryption layer (AES-GCM) - JUSTIFIED: Security requirement, native CryptoKit, minimal code
- MVVM pattern - JUSTIFIED: SwiftUI best practice, testable, clear separation of concerns

**Verdict**: ✅ No unjustified complexity. All additions support core requirements.

---

#### V. Observability and Debuggability ✅ COMPLIANT

**Design Support**:
- Logging: data-model.md documents "Never Logged" sensitive fields
- Error States: data-model.md defines ValidationError enums for Token, Vault
- User-Facing Errors: quickstart.md documents error handling (Keychain unavailable, sync issues)
- Debugging: quickstart.md includes "Debugging Tips" section

**No Violations**: Design includes observability requirements.

---

### Gate Summary (Post-Design)

**Result**: ✅ ALL GATES PASS (Re-confirmed)

- All five constitution principles remain compliant after design phase
- No new violations introduced by design artifacts
- Complexity additions (custom Base32, encryption, MVVM) justified and minimal
- Design reinforces TDD, security, simplicity, and Apple standards

**Approved for Phase 2**: Proceed to task generation (`/speckit.tasks`)

---
