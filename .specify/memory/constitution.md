<!--
Sync Impact Report:
─────────────────────────────────────────────────────────────────
Version Change: 0.0.0 → 1.0.0
Modified Principles: N/A (initial ratification)
Added Sections:
  - Core Principles (5 principles focused on TDD and quality)
  - Security Requirements (critical for 2FA application)
  - Development Workflow (TDD enforcement)
  - Governance
Removed Sections: N/A
Templates Status:
  ✅ plan-template.md - Constitution Check section aligns
  ✅ spec-template.md - User scenarios support testable requirements
  ✅ tasks-template.md - Test-first ordering enforced
Follow-up TODOs: None
─────────────────────────────────────────────────────────────────
-->

# Second Constitution

## Core Principles

### I. Test-First Development (NON-NEGOTIABLE)

**TDD is mandatory for all features and bug fixes.**

- Tests MUST be written before implementation code
- Red-Green-Refactor cycle strictly enforced:
  1. **Red**: Write a failing test that defines desired behavior
  2. **Green**: Write minimal code to make the test pass
  3. **Refactor**: Improve code while keeping tests green
- No code merged without corresponding tests
- Test coverage MUST include:
  - Unit tests for business logic
  - Integration tests for system boundaries (iCloud sync, Keychain access)
  - Contract tests for data models and encryption schemes

**Rationale**: TDD ensures correctness from the start, reduces debugging time, provides living documentation, and enables confident refactoring. For a security-sensitive 2FA application, this discipline is non-negotiable.

### II. Security-First Architecture

**Security is a primary concern, not an afterthought.**

- All TOTP secrets MUST remain encrypted at rest and in transit
- Encryption MUST use Apple's CryptoKit (AES-GCM)
- Vault keys MUST be stored only in Keychain with `kSecAttrSynchronizable = true`
- iCloud storage MUST contain only ciphertext, never plaintext or keys
- No telemetry, analytics, or network calls except to iCloud
- Security-critical code changes MUST undergo peer review
- Threat model MUST be documented and updated when architecture changes

**Rationale**: Users trust this app with their 2FA codes. A single security flaw could compromise all their accounts. Defense-in-depth and zero-trust principles protect against both external attackers and Apple infrastructure compromises.

### III. Apple Ecosystem Standards

**Follow Apple's recommended patterns and technologies.**

- Swift as primary language (no Objective-C unless interfacing with legacy APIs)
- SwiftUI for UI (declarative, testable, modern)
- Structured Concurrency (async/await) over completion handlers
- CryptoKit for cryptography (no third-party crypto libraries)
- CloudKit or iCloud Drive for sync (decision documented in plan.md)
- XCTest for testing framework
- Swift Package Manager for dependencies (minimize external dependencies)

**Rationale**: Apple's frameworks are optimized for their platforms, regularly audited, and provide the best integration with OS features like Keychain sync and iCloud. Using standard patterns makes the codebase maintainable and auditable.

### IV. Simplicity and Minimalism

**Do one thing well: TOTP. No feature creep.**

- Only TOTP (RFC 6238) - no passwords, no passkeys, no other credential types
- No account system - rely on Apple ID
- No backend servers - rely on iCloud
- No analytics or tracking
- UI must be clean, intuitive, and fast
- Every feature addition must justify its existence against the "extreme simplicity" goal

**Rationale**: Scope creep leads to complexity, bugs, and security vulnerabilities. A focused app is easier to test, audit, and trust. Users chose this app specifically because it's NOT a bloated password manager.

### V. Observability and Debuggability

**Make the system transparent and diagnosable.**

- Structured logging for all critical operations (Keychain access, encryption/decryption, iCloud sync events)
- Log levels: ERROR, WARNING, INFO, DEBUG
- NO logging of secrets, keys, or plaintext TOTP codes
- Clear error messages for users when sync fails or Keychain is unavailable
- Assertions and preconditions for invariants
- Performance instrumentation for encryption and TOTP generation (must be <50ms)

**Rationale**: When sync issues or Keychain problems occur (common in iOS ecosystems), clear logs help users and developers diagnose the problem. Security-sensitive data must never appear in logs.

## Security Requirements

### Encryption Standards

- Algorithm: AES-256-GCM (via CryptoKit's `AES.GCM`)
- Key derivation: Random 256-bit key generated once per Apple ID
- Nonce: Unique per encryption operation, stored with ciphertext
- Authentication: GCM tag verified before decryption

### Keychain Usage

- Service identifier: `com.second.vaultKey`
- Access control: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for local, `kSecAttrAccessibleAfterFirstUnlock` for synced
- Synchronizable: `true` for vault key (MUST sync across devices)
- Keychain tests MUST run on simulator AND physical device

### Data at Rest

- iCloud storage format: Encrypted JSON blob
- Local cache (if any): Also encrypted with same vault key
- Deleted items: Securely zeroed from memory, removed from iCloud

### Threat Model (Documented)

**Protected against:**
- iCloud data breach (attacker sees only ciphertext)
- Device loss (data encrypted, Keychain protected by device passcode)
- Malicious apps (Keychain sandboxing)

**NOT protected against:**
- Compromised device with full access (jailbreak, malware with root)
- User losing all devices AND iCloud Keychain access
- Quantum computers (AES-256 currently considered quantum-resistant for practical purposes)

**Out of scope:**
- Multi-platform support (Android, Windows)
- Self-hosted sync
- Offline backup/export (intentionally omitted to prevent key exfiltration)

## Development Workflow

### Test-First Workflow (Enforced)

1. **Feature Specification**: Write testable user stories with Given-When-Then acceptance criteria
2. **Test Writing**: Implement tests that exercise the specification
3. **Test Failure**: Verify all new tests fail with clear error messages
4. **Implementation**: Write minimum code to pass tests
5. **Refactor**: Clean up code while maintaining green tests
6. **Review**: Peer review checks test quality and coverage
7. **Merge**: Only merge when all tests pass

### Code Quality Gates

**All PRs must pass:**
- SwiftLint (no warnings)
- All unit tests (100% of new code paths tested)
- All integration tests
- Security review checklist (for crypto/Keychain changes)
- Performance benchmarks (<50ms for TOTP generation, <200ms for decryption)

### Branching and Versioning

- Semantic versioning: MAJOR.MINOR.PATCH
  - **MAJOR**: Breaking changes to data model or encryption scheme (requires migration)
  - **MINOR**: New features (e.g., SHA-256 support, search)
  - **PATCH**: Bug fixes, UI tweaks
- Feature branches: `###-feature-name` format
- Main branch: `main` (always deployable)

### Review Requirements

- All code changes require peer review
- Security-critical changes (crypto, Keychain, iCloud sync) require TWO reviews
- Test changes reviewed for correctness and completeness
- No self-merging

## Governance

**This constitution supersedes all other development practices.**

### Amendment Process

1. Propose amendment in `.specify/memory/constitution.md`
2. Increment version according to semantic versioning:
   - MAJOR: Removing or fundamentally changing a principle
   - MINOR: Adding a new principle or section
   - PATCH: Clarifications, typo fixes, non-semantic improvements
3. Update `LAST_AMENDED_DATE` to current date
4. Propagate changes to dependent templates (plan, spec, tasks)
5. Document in Sync Impact Report
6. Commit with message: `docs: amend constitution to vX.Y.Z (description)`

### Compliance

- All PRs MUST verify compliance with constitution principles
- Plan files (plan.md) MUST include "Constitution Check" section
- Task files (tasks.md) MUST order tests before implementation
- Any deviation from constitution MUST be justified in writing and reviewed

### Complexity Justification

If a feature violates simplicity principle (Principle IV), it MUST be justified:
- **What problem does this solve?**
- **Why can't a simpler approach work?**
- **What is the maintenance cost?**

Unjustified complexity will be rejected.

### Living Document

This constitution is a living document. As the project evolves:
- Keep principles relevant to current goals
- Remove outdated constraints
- Add new principles only when patterns emerge repeatedly
- Prefer deleting over adding

**Version**: 1.0.0 | **Ratified**: 2026-01-15 | **Last Amended**: 2026-01-15
