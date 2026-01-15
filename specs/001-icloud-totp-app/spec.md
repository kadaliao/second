# Feature Specification: iCloud-Synced 2FA (TOTP) Application

**Feature Branch**: `001-icloud-totp-app`
**Created**: 2026-01-15
**Status**: Draft
**Input**: User description: "极简 iCloud 同步 2FA（TOTP）应用 - 一款纯 2FA 验证码应用，无账号系统，无自建服务器,依赖 Apple 生态完成同步与安全"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time Setup and Add First 2FA Token (Priority: P1)

A user installs the app for the first time and adds their first 2FA token by scanning a QR code or manually entering credentials.

**Why this priority**: This is the core functionality - without the ability to add and view tokens, the app has no value. It represents the minimum viable product.

**Independent Test**: Can be fully tested by installing the app on a fresh device, adding one token via QR scan or manual entry, and verifying that a 6-digit TOTP code is displayed and refreshes every 30 seconds.

**Acceptance Scenarios**:

1. **Given** a fresh app installation, **When** the user opens the app for the first time, **Then** they see an empty list with a "+" button and guidance text "Tap + to add your first account"
2. **Given** the user taps the "+" button, **When** they select "Scan QR Code", **Then** the camera opens and can scan an otpauth:// QR code
3. **Given** the user successfully scans a QR code, **When** the token is added, **Then** they see a card displaying the issuer name, account identifier, current 6-digit code, and a countdown timer
4. **Given** the user taps the "+" button, **When** they select "Enter Manually" and provide issuer, account, and secret key, **Then** the token is added successfully
5. **Given** a token is displayed, **When** the 30-second period ends, **Then** a new TOTP code is automatically generated and displayed
6. **Given** a token card is displayed, **When** the user taps on it, **Then** the code is copied to clipboard and a "Copied to clipboard" toast notification appears

---

### User Story 2 - View and Copy Multiple Tokens (Priority: P1)

A user with multiple 2FA tokens can view all their tokens in a list, search for specific tokens, and quickly copy codes.

**Why this priority**: Once users can add tokens, they need to manage multiple accounts. This is essential for daily use and completes the core read/write functionality.

**Independent Test**: Can be tested by adding 3-5 tokens with different issuers, using the search to filter, and copying codes from different tokens to verify clipboard functionality.

**Acceptance Scenarios**:

1. **Given** multiple tokens are added, **When** the user views the main screen, **Then** all tokens are displayed as cards in a scrollable list
2. **Given** the user types in the search bar, **When** they enter text matching an issuer or account name, **Then** only matching tokens are displayed
3. **Given** multiple tokens exist, **When** the user taps any token card, **Then** that specific token's code is copied to clipboard
4. **Given** tokens are displayed, **When** each token's timer reaches 5 seconds remaining, **Then** the timer circle changes to red color to indicate urgency
5. **Given** the search bar has text, **When** no tokens match the search, **Then** an empty state is displayed with appropriate messaging

---

### User Story 3 - Edit and Delete Tokens (Priority: P2)

A user can edit the issuer or account name of existing tokens, or delete tokens they no longer need.

**Why this priority**: While not essential for initial use, users will need this for maintenance as their accounts change or they stop using services.

**Independent Test**: Can be tested by adding a token, editing its issuer/account name, verifying the changes persist, then deleting the token and confirming it's removed.

**Acceptance Scenarios**:

1. **Given** a token exists, **When** the user performs a long-press or swipe gesture on the token card, **Then** edit and delete options appear
2. **Given** the user selects "Edit", **When** they modify the issuer or account name and save, **Then** the token displays the updated information
3. **Given** the user selects "Delete", **When** they confirm the deletion, **Then** the token is permanently removed from the list
4. **Given** the user selects "Delete", **When** it's their last token, **Then** the app returns to the empty state after confirmation

---

### User Story 4 - Automatic Cross-Device Sync (Priority: P1)

A user with the same Apple ID on multiple devices (iPhone, iPad, Mac) sees their tokens automatically sync across all devices without any manual setup.

**Why this priority**: This is a core differentiator and value proposition of the app - seamless sync via iCloud without accounts or configuration.

**Independent Test**: Can be tested by adding tokens on an iPhone logged into Apple ID X, then opening the app on an iPad with the same Apple ID and verifying all tokens appear automatically.

**Acceptance Scenarios**:

1. **Given** a user adds a token on Device A (logged into Apple ID X), **When** they open the app on Device B (same Apple ID X), **Then** the token appears automatically without any user action
2. **Given** tokens exist on multiple devices, **When** a user deletes a token on Device A, **Then** the token is removed from Device B within a reasonable sync interval
3. **Given** a user edits a token on Device A, **When** Device B syncs with iCloud, **Then** the updated token information appears on Device B
4. **Given** a user installs the app on a new device, **When** they open it for the first time (with existing iCloud data), **Then** all previously added tokens appear automatically

---

### User Story 5 - Secure Encryption and Recovery (Priority: P1)

A user's 2FA tokens are encrypted before being stored in iCloud, ensuring that even if iCloud data is compromised, the tokens remain secure.

**Why this priority**: Security is a critical requirement for a 2FA app. Users must trust that their sensitive authentication data is protected.

**Independent Test**: Can be tested by examining the iCloud data directly (developer tools) to verify it's encrypted, and by attempting to decrypt on a device without the proper Keychain key.

**Acceptance Scenarios**:

1. **Given** a user adds a token, **When** the data is written to iCloud, **Then** only encrypted ciphertext is stored (no plaintext secrets)
2. **Given** encrypted data exists in iCloud, **When** a device attempts to access it without the vault key in iCloud Keychain, **Then** the app displays a read-only error state with guidance
3. **Given** a user has iCloud Keychain disabled, **When** they try to use the app on a second device, **Then** they see an error message: "检测到你的验证码数据已从 iCloud 同步,但解密密钥不可用。请确认已开启 iCloud 钥匙串。"
4. **Given** a user loses all their devices but iCloud Keychain is recoverable, **When** they install the app on a new device and sign in with their Apple ID, **Then** their tokens are automatically restored

---

### Edge Cases

- What happens when a user scans an invalid QR code (not otpauth:// format)?
  - The app should display an error message and allow the user to try again
- What happens when a user manually enters an invalid Base32 secret key?
  - The app should validate the key format and display an error if invalid
- What happens when iCloud sync is temporarily unavailable (no network)?
  - Changes are stored locally and sync automatically when connectivity returns
- What happens when a user switches Apple IDs on their device?
  - The vault key from the previous Apple ID won't be available, so the app should show the error state for incompatible Keychain
- What happens when a token uses non-standard TOTP parameters (8 digits, SHA256, 60-second period)?
  - The app should parse and respect these parameters from the otpauth:// URI
- What happens when a user uninstalls and reinstalls the app?
  - All data should be restored from iCloud automatically (assuming same Apple ID and iCloud Keychain enabled)
- What happens when the system clock is incorrect?
  - TOTP codes will be incorrect; the app should display a warning if clock skew is detected
- What happens when a user adds a duplicate token (same issuer + account)?
  - The system allows duplicate tokens. Users can add the same issuer + account combination multiple times, giving them flexibility but requiring manual deletion of unwanted duplicates if needed

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support TOTP code generation according to RFC 6238
- **FR-002**: System MUST support default TOTP parameters: 6 digits, 30-second period, SHA1 algorithm
- **FR-003**: System MUST support common TOTP variants: 8 digits, SHA256/SHA512 algorithms, custom periods
- **FR-004**: System MUST allow users to add tokens via QR code scanning (otpauth:// URI format)
- **FR-005**: System MUST allow users to add tokens via manual entry (issuer, account, secret key)
- **FR-006**: System MUST validate Base32 secret keys during manual entry
- **FR-007**: System MUST display current TOTP code for each token
- **FR-008**: System MUST refresh TOTP codes automatically at the end of each time period
- **FR-009**: System MUST display a countdown timer (visual progress indicator) for each token
- **FR-010**: System MUST change timer color to red when 5 or fewer seconds remain
- **FR-011**: System MUST copy TOTP code to clipboard when user taps on a token card
- **FR-012**: System MUST display a toast notification confirming clipboard copy
- **FR-013**: System MUST provide real-time search/filter functionality by issuer or account name
- **FR-014**: System MUST allow users to edit issuer and account names for existing tokens
- **FR-015**: System MUST allow users to delete tokens with confirmation
- **FR-016**: System MUST generate a random encryption key (vault key) on first launch if none exists
- **FR-017**: System MUST store the vault key in iCloud Keychain with synchronizable flag enabled
- **FR-018**: System MUST encrypt all token data using AES-GCM before storing in iCloud
- **FR-019**: System MUST store only encrypted data in iCloud (never plaintext secrets)
- **FR-020**: System MUST automatically sync encrypted vault data across devices via iCloud
- **FR-021**: System MUST decrypt vault data using the key from iCloud Keychain
- **FR-022**: System MUST detect when encrypted data exists but vault key is unavailable
- **FR-023**: System MUST display error state with guidance when vault key is missing
- **FR-024**: System MUST NOT require user registration or login
- **FR-025**: System MUST NOT collect user identity information
- **FR-026**: System MUST NOT communicate with any backend servers
- **FR-027**: System MUST display empty state with guidance when no tokens exist
- **FR-028**: System MUST support iOS light and dark mode appearances
- **FR-029**: System MUST persist token data locally in-memory during app session
- **FR-030**: System MUST format TOTP codes with spacing for readability (e.g., "123 456")

### Key Entities

- **Token**: Represents a single 2FA account entry
  - Attributes: issuer (service name), account (username/email), secret (Base32 encoded), digits (6 or 8), period (typically 30s), algorithm (SHA1/SHA256/SHA512), created_at, updated_at
  - Relationships: Belongs to a Vault

- **Vault**: The encrypted container for all tokens
  - Attributes: encrypted_data (JSON ciphertext), encryption_algorithm (AES-GCM), last_modified
  - Storage: iCloud Drive container or CloudKit private database

- **Vault Key**: The encryption/decryption key for the Vault
  - Attributes: key_data (random bytes), key_identifier
  - Storage: iCloud Keychain (synchronizable)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add their first 2FA token in under 30 seconds from app launch
- **SC-002**: Users can copy a TOTP code to clipboard with a single tap
- **SC-003**: New tokens added on one device appear on all other devices (same Apple ID) within 10 seconds under normal network conditions
- **SC-004**: Users can successfully add and view tokens without any registration, login, or account creation steps
- **SC-005**: 100% of token secret keys are stored only in encrypted form in iCloud (verified via iCloud data inspection)
- **SC-006**: Users with iCloud Keychain enabled can recover all tokens after device loss by signing into a new device
- **SC-007**: Search filters token list in real-time with results appearing as user types (under 100ms response)
- **SC-008**: TOTP codes are generated accurately within 1 second of time period rollover
- **SC-009**: The app functions for users managing up to 50 tokens without performance degradation
- **SC-010**: Users understand the sync mechanism without reading documentation (no confusion about "login" or "account creation")

## Assumptions

- **A-001**: Users have iCloud enabled on their devices
- **A-002**: Users have iCloud Keychain enabled for cross-device key sync
- **A-003**: Users are within the Apple ecosystem (iOS, iPadOS, macOS)
- **A-004**: Users have reliable internet connectivity for iCloud sync
- **A-005**: The app targets iOS 16+ to leverage modern CryptoKit APIs
- **A-006**: QR codes follow the standard otpauth:// URI format
- **A-007**: Users understand that losing access to their Apple ID means losing access to encrypted tokens
- **A-008**: System clock on devices is reasonably accurate (within 30 seconds of actual time)
- **A-009**: iCloud storage quota is sufficient for the encrypted vault file (typically under 1MB for 50 tokens)

## Dependencies

- **D-001**: Apple iCloud infrastructure for data sync
- **D-002**: Apple iCloud Keychain for encryption key sync
- **D-003**: Device camera access permission for QR code scanning
- **D-004**: Clipboard access for code copying
- **D-005**: System time accuracy for TOTP generation

## Out of Scope

The following are explicitly NOT included in this feature:

- Password management or storage
- Web browser autofill integration
- Multi-platform support (Android, Windows, Linux)
- Self-hosted backend or cloud infrastructure
- User accounts, authentication, or identity management
- Social features, sharing, or team collaboration
- Export/import to other 2FA apps
- Backup to non-iCloud services
- Biometric authentication (FaceID/TouchID) for app access
- Widgets or Today View extensions
- Watch app or complications
- Siri integration
- Push notifications
- Analytics or telemetry collection
