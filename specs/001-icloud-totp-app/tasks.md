# Tasks: iCloud-Synced 2FA (TOTP) Application

**Input**: Design documents from `/specs/001-icloud-totp-app/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Following TDD principles (Constitution Principle I), all test tasks are REQUIRED and must be written FIRST before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Per plan.md project structure:
- **App target**: `Second/` (iOS app)
- **Test target**: `SecondTests/`
- **Models**: `Second/Models/`
- **Services**: `Second/Services/`
- **Views**: `Second/Views/`, `Second/Views/Components/`
- **ViewModels**: `Second/ViewModels/`
- **Utilities**: `Second/Utilities/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Xcode project initialization and basic structure

- [x] T001 Create Xcode iOS app project "Second" with Swift 5.9+, iOS 16+ deployment target
- [x] T002 Configure Info.plist with NSCameraUsageDescription: "需要使用相机扫描二维码以添加验证码"
- [x] T003 Add iCloud capability with Key-Value Storage entitlement
- [x] T004 Add iCloud Keychain entitlement (kSecAttrSynchronizable support)
- [x] T005 [P] Create directory structure: Second/{App,Views,Views/Components,ViewModels,Models,Services,Utilities}
- [x] T006 [P] Create test directory structure: SecondTests/{Unit,Integration,Contract}
- [x] T007 [P] Create Resources/Assets.xcassets with App Icon placeholder and color sets (light/dark mode)
- [x] T008 Configure SwiftLint or Swift Format (optional - per team preference)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core services and models that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Foundational Tests (TDD - Write FIRST)

- [x] T009 [P] Contract test for Token Codable schema in SecondTests/Contract/TokenSchemaTests.swift
- [x] T010 [P] Contract test for Vault Codable schema in SecondTests/Contract/VaultFormatTests.swift
- [x] T011 [P] Contract test for otpauth:// URI parsing in SecondTests/Contract/OTPAuthURITests.swift
- [x] T012 [P] Unit test for TOTP generation (RFC 6238 test vectors) in SecondTests/Unit/TOTPGeneratorTests.swift
- [x] T013 [P] Unit test for Base32 decoder (RFC 4648 test vectors) in SecondTests/Unit/Base32DecoderTests.swift
- [x] T014 [P] Unit test for AES-GCM encryption/decryption in SecondTests/Unit/EncryptionServiceTests.swift
- [x] T015 Integration test for Keychain save/load in SecondTests/Integration/KeychainServiceTests.swift
- [x] T016 Integration test for iCloud KVStore mock operations in SecondTests/Integration/iCloudSyncTests.swift
- [x] T017 Integration test for end-to-end vault encrypt→save→load→decrypt in SecondTests/Integration/VaultIntegrationTests.swift

### Foundational Implementation

- [x] T018 [P] Create TOTPAlgorithm enum in Second/Models/TOTPParameters.swift
- [x] T019 [P] Create Token model with Codable, validation in Second/Models/Token.swift
- [x] T020 [P] Create Vault model with addToken/updateToken/deleteToken in Second/Models/Vault.swift
- [x] T021 Implement Base32Decoder per RFC 4648 in Second/Services/Base32Decoder.swift
- [x] T022 Implement TOTPGenerator per RFC 6238 using CryptoKit HMAC in Second/Services/TOTPGenerator.swift
- [x] T023 Implement EncryptionService with AES-GCM encrypt/decrypt in Second/Services/EncryptionService.swift
- [x] T024 Implement KeychainService with save/load/delete vault key (kSecAttrSynchronizable=true) in Second/Services/KeychainService.swift
- [x] T025 Implement iCloudSyncService with NSUbiquitousKeyValueStore save/load/observe in Second/Services/iCloudSyncService.swift
- [x] T026 [P] Implement Logger utility with structured logging (no secrets) in Second/Utilities/Logger.swift
- [x] T027 [P] Implement ClipboardHelper utility with copy + toast in Second/Utilities/ClipboardHelper.swift

**Checkpoint**: Foundation ready - all tests pass, core crypto/sync/storage services operational

---

## Phase 3: User Story 1 - First-Time Setup and Add First 2FA Token (Priority: P1) 🎯 MVP

**Goal**: Enable users to install the app, add their first 2FA token via QR scan or manual entry, and see a working TOTP code with countdown timer

**Independent Test**: Install on fresh device, add one token via QR or manual, verify 6-digit code displays and refreshes every 30 seconds

### Tests for User Story 1 (TDD - Write FIRST)

- [ ] T028 [P] [US1] Unit test for QRCodeParser with valid/invalid otpauth:// URIs in SecondTests/Unit/QRCodeParserTests.swift
- [ ] T029 [P] [US1] Unit test for Token validation (empty issuer, invalid secret, invalid digits) in SecondTests/Unit/TokenTests.swift
- [ ] T030 [US1] Integration test for "add first token" flow (empty vault → add token → save → reload) in SecondTests/Integration/AddTokenIntegrationTests.swift

### Implementation for User Story 1

- [ ] T031 [US1] Create SecondApp.swift (@main entry point) with iCloud setup in Second/App/SecondApp.swift
- [ ] T032 [P] [US1] Create EmptyStateView component ("Tap + to add your first account") in Second/Views/Components/EmptyStateView.swift
- [ ] T033 [P] [US1] Create CountdownTimerView component (circular progress) in Second/Views/Components/CountdownTimerView.swift
- [ ] T034 [P] [US1] Create TokenCardView component (issuer, account, code, timer) in Second/Views/Components/TokenCardView.swift
- [ ] T035 [US1] Implement QRCodeParser for otpauth:// URI parsing in Second/Services/QRCodeParser.swift
- [ ] T036 [US1] Create QRCodeScannerView (UIViewControllerRepresentable with AVFoundation) in Second/Views/Components/QRCodeScannerView.swift
- [ ] T037 [US1] Create AddTokenViewModel with QR scan + manual entry logic in Second/ViewModels/AddTokenViewModel.swift
- [ ] T038 [US1] Create AddTokenView modal (scan QR / manual entry form) in Second/Views/AddTokenView.swift
- [ ] T039 [US1] Create TokenListViewModel with load/save vault, timer publisher for TOTP refresh in Second/ViewModels/TokenListViewModel.swift
- [ ] T040 [US1] Create TokenListView (main screen: list + search bar + "+" button) in Second/Views/TokenListView.swift
- [ ] T041 [US1] Implement first-launch vault key generation in TokenListViewModel.onAppear()
- [ ] T042 [US1] Wire up AddTokenView presentation from TokenListView "+" button
- [ ] T043 [US1] Add clipboard copy on token card tap with toast notification
- [ ] T044 [US1] Add validation and error handling for invalid QR codes / Base32 secrets

**Checkpoint**: User Story 1 complete - users can add first token, see TOTP codes, copy to clipboard

---

## Phase 4: User Story 2 - View and Copy Multiple Tokens (Priority: P1)

**Goal**: Enable users to manage multiple tokens, search/filter by issuer or account, and quickly copy codes

**Independent Test**: Add 3-5 tokens with different issuers, use search to filter, copy codes from different tokens

### Tests for User Story 2 (TDD - Write FIRST)

- [ ] T045 [P] [US2] Unit test for search filter logic in SecondTests/Unit/TokenListViewModelTests.swift
- [ ] T046 [US2] Integration test for "multiple tokens" flow (add 3 tokens, search, copy) in SecondTests/Integration/MultiTokenIntegrationTests.swift

### Implementation for User Story 2

- [ ] T047 [US2] Add @Published searchText property to TokenListViewModel
- [ ] T048 [US2] Implement filteredTokens computed property with case-insensitive issuer/account search in TokenListViewModel
- [ ] T049 [US2] Add search bar to TokenListView bound to searchText
- [ ] T050 [US2] Add empty search state view ("No matching tokens") when filter returns no results
- [ ] T051 [US2] Add timer color change to red when ≤ 5 seconds remaining in CountdownTimerView
- [ ] T052 [US2] Test and optimize search performance for 50 tokens (SC-007: <100ms response)
- [ ] T053 [US2] Add TOTP code formatting with spacing (e.g., "123 456") in TokenCardView

**Checkpoint**: User Story 2 complete - users can manage multiple tokens, search efficiently, codes format correctly

---

## Phase 5: User Story 3 - Edit and Delete Tokens (Priority: P2)

**Goal**: Enable users to edit issuer/account names or delete unwanted tokens

**Independent Test**: Add token, edit its issuer/account, verify changes persist, then delete and confirm removal

### Tests for User Story 3 (TDD - Write FIRST)

- [ ] T054 [P] [US3] Unit test for Vault.updateToken() logic in SecondTests/Unit/VaultTests.swift
- [ ] T055 [P] [US3] Unit test for Vault.deleteToken() logic in SecondTests/Unit/VaultTests.swift
- [ ] T056 [US3] Integration test for "edit token" flow (edit → save → reload → verify) in SecondTests/Integration/EditTokenIntegrationTests.swift
- [ ] T057 [US3] Integration test for "delete token" flow (delete → save → reload → verify) in SecondTests/Integration/DeleteTokenIntegrationTests.swift

### Implementation for User Story 3

- [ ] T058 [US3] Create EditTokenViewModel with save/cancel logic in Second/ViewModels/EditTokenViewModel.swift
- [ ] T059 [US3] Create EditTokenView modal (edit issuer/account form) in Second/Views/EditTokenView.swift
- [ ] T060 [US3] Add swipe-to-delete gesture to TokenCardView in TokenListView
- [ ] T061 [US3] Add long-press gesture to TokenCardView showing Edit/Delete context menu
- [ ] T062 [US3] Implement delete confirmation alert in TokenListViewModel
- [ ] T063 [US3] Wire up EditTokenView presentation from context menu "Edit"
- [ ] T064 [US3] Update vault and sync to iCloud after edit in EditTokenViewModel
- [ ] T065 [US3] Update vault and sync to iCloud after delete in TokenListViewModel
- [ ] T066 [US3] Handle edge case: deleting last token returns to empty state

**Checkpoint**: User Story 3 complete - users can edit/delete tokens with proper confirmation and persistence

---

## Phase 6: User Story 4 - Automatic Cross-Device Sync (Priority: P1)

**Goal**: Enable seamless automatic sync across all devices logged into the same Apple ID

**Independent Test**: Add tokens on iPhone with Apple ID X, open app on iPad with same Apple ID, verify tokens appear automatically

### Tests for User Story 4 (TDD - Write FIRST)

- [ ] T067 [US4] Integration test for iCloud change notification handling in SecondTests/Integration/iCloudSyncNotificationTests.swift
- [ ] T068 [US4] Integration test for sync conflict resolution (last-write-wins) in SecondTests/Integration/SyncConflictTests.swift

### Implementation for User Story 4

- [ ] T069 [US4] Create SyncViewModel with sync status (@Published isSyncing, lastSyncDate) in Second/ViewModels/SyncViewModel.swift
- [ ] T070 [US4] Implement NSUbiquitousKeyValueStore.didChangeExternallyNotification observer in iCloudSyncService
- [ ] T071 [US4] Add sync notification handler in TokenListViewModel (reload vault on external change)
- [ ] T072 [US4] Call NSUbiquitousKeyValueStore.synchronize() after every vault save in iCloudSyncService
- [ ] T073 [US4] Add sync status indicator to TokenListView (optional: small icon or text)
- [ ] T074 [US4] Test sync propagation timing (SC-003: <10 seconds under normal network)
- [ ] T075 [US4] Handle offline mode gracefully (queue changes, sync when online)

**Checkpoint**: User Story 4 complete - tokens sync automatically across devices within 10 seconds

---

## Phase 7: User Story 5 - Secure Encryption and Recovery (Priority: P1)

**Goal**: Ensure all iCloud data is encrypted and provide clear error states when vault key is unavailable

**Independent Test**: Inspect iCloud data to verify encryption, attempt access on device without Keychain key

### Tests for User Story 5 (TDD - Write FIRST)

- [ ] T076 [P] [US5] Unit test for encryption produces different ciphertext for same plaintext (unique nonces) in SecondTests/Unit/EncryptionServiceTests.swift
- [ ] T077 [P] [US5] Unit test for decryption fails with wrong key (authentication failure) in SecondTests/Unit/EncryptionServiceTests.swift
- [ ] T078 [US5] Integration test for "vault key missing" error state in SecondTests/Integration/MissingKeyTests.swift

### Implementation for User Story 5

- [ ] T079 [US5] Create ErrorStateView with error message and guidance in Second/Views/ErrorStateView.swift
- [ ] T080 [US5] Add vault key detection logic in TokenListViewModel.onAppear()
- [ ] T081 [US5] Show ErrorStateView when encrypted vault exists but key missing (FR-022, FR-023)
- [ ] T082 [US5] Display Chinese error message: "检测到你的验证码数据已从 iCloud 同步,但解密密钥不可用。请确认已开启 iCloud 钥匙串。"
- [ ] T083 [US5] Add logging for encryption/decryption operations (no secrets in logs) in EncryptionService
- [ ] T084 [US5] Add logging for Keychain operations (save/load/missing key) in KeychainService
- [ ] T085 [US5] Verify no plaintext secrets in iCloud storage (code review + manual inspection)
- [ ] T086 [US5] Test vault recovery on new device with iCloud Keychain enabled

**Checkpoint**: User Story 5 complete - encryption verified, error states guide users, recovery tested

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Refinements that affect multiple user stories

- [ ] T087 [P] Add light/dark mode color adaptations in Resources/Assets.xcassets
- [ ] T088 [P] Optimize TOTP generation performance (<50ms per FR-020)
- [ ] T089 [P] Optimize vault decryption performance (<200ms per FR-020)
- [ ] T090 [P] Verify 60 fps UI performance with 50 tokens loaded
- [ ] T091 Add accessibility labels for VoiceOver support
- [ ] T092 Add haptic feedback for token copy action
- [ ] T093 Validate app against quickstart.md examples
- [ ] T094 [P] Add inline code documentation for public APIs
- [ ] T095 Security audit: Review all crypto/Keychain/iCloud code for vulnerabilities
- [ ] T096 [P] Add App Store assets: screenshots, description, privacy policy
- [ ] T097 Final end-to-end testing on physical devices (iPhone, iPad)
- [ ] T098 Submit for TestFlight beta testing

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User stories CAN proceed in parallel (if staffed)
  - OR sequentially in priority order: US1 → US2 → US4 → US5 → US3
  - **Recommended MVP**: US1 only (add first token) - fully functional standalone
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories ✅ FULLY INDEPENDENT
- **User Story 2 (P1)**: Extends US1 (search/multiple tokens) - Requires US1 complete first
- **User Story 3 (P2)**: Extends US1 (edit/delete) - Requires US1 complete first
- **User Story 4 (P1)**: Extends US1 (sync) - Requires US1 complete first ✅ CAN START AFTER US1
- **User Story 5 (P1)**: Extends US1 (security/errors) - Requires US1 complete first ✅ CAN START AFTER US1

### Within Each User Story

- **Tests FIRST** (TDD): All test tasks MUST be written and FAIL before implementation
- Models before services
- Services before views/viewmodels
- ViewModels before views
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- **Setup**: T003-T008 can run in parallel
- **Foundational Tests**: T009-T017 can run in parallel (all test files)
- **Foundational Models**: T018-T020 can run in parallel (different files)
- **Foundational Services**: T021-T025 can run in parallel after models complete
- **User Story 1 Tests**: T028-T029 can run in parallel
- **User Story 1 Components**: T032-T034 can run in parallel (different view components)
- **After US1 Complete**: US2, US4, US5 can be worked on by different developers in parallel
- **Polish**: T087-T090, T094, T096 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Step 1: Launch all US1 tests together (TDD - write first):
Task T028: "Unit test for QRCodeParser with valid/invalid otpauth:// URIs"
Task T029: "Unit test for Token validation (empty issuer, invalid secret)"
# These tests MUST fail initially

# Step 2: Launch all US1 view components together:
Task T032: "Create EmptyStateView component"
Task T033: "Create CountdownTimerView component"
Task T034: "Create TokenCardView component"

# Step 3: After services exist, implement ViewModels:
Task T037: "Create AddTokenViewModel"
Task T039: "Create TokenListViewModel"

# Step 4: Wire up views:
Task T038: "Create AddTokenView modal"
Task T040: "Create TokenListView main screen"
```

---

## Parallel Example: After Foundational Complete

```bash
# If you have 3 developers, they can work in parallel:

Developer A: Complete User Story 1 (T028-T044)
Developer B: Complete User Story 4 (T067-T075) - depends on US1 Models/Services
Developer C: Complete User Story 5 (T076-T086) - depends on US1 Models/Services

# OR prioritize sequentially for single developer:
1. US1 first (MVP - add tokens, see codes)
2. US4 second (sync - critical for multi-device)
3. US5 third (security - critical for trust)
4. US2 fourth (search - nice to have)
5. US3 fifth (edit/delete - maintenance feature)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only) - RECOMMENDED START

1. Complete Phase 1: Setup (T001-T008)
2. Complete Phase 2: Foundational (T009-T027) - **CRITICAL BLOCKER**
3. Complete Phase 3: User Story 1 (T028-T044)
4. **STOP and VALIDATE**: Test US1 independently on physical device
5. Deploy to TestFlight if ready
6. **Result**: Fully functional 2FA app with QR scan, manual entry, TOTP codes, clipboard copy

### Incremental Delivery (Recommended Order)

1. Setup + Foundational → Foundation ready (T001-T027)
2. Add User Story 1 → Test independently → **Deploy MVP!** (T028-T044)
3. Add User Story 4 → Test sync across devices → Deploy v1.1 (T067-T075)
4. Add User Story 5 → Test encryption/errors → Deploy v1.2 (T076-T086)
5. Add User Story 2 → Test search/multiple tokens → Deploy v1.3 (T045-T053)
6. Add User Story 3 → Test edit/delete → Deploy v1.4 (T054-T066)
7. Polish → Final release (T087-T098)

### Parallel Team Strategy

With 2-3 developers:

1. **All developers**: Complete Setup + Foundational together (T001-T027)
2. **Once Foundational done (CRITICAL GATE)**:
   - Developer A: User Story 1 (T028-T044)
   - Developer B: User Story 4 after A finishes US1 models (T067-T075)
   - Developer C: User Story 5 after A finishes US1 models (T076-T086)
3. **Integration**: Stories merge independently, test together

---

## Success Metrics (from spec.md)

After all tasks complete, verify:

- **SC-001**: Users can add first token in <30 seconds ✅ (US1)
- **SC-002**: Copy code with single tap ✅ (US1)
- **SC-003**: Sync appears on other devices <10 seconds ✅ (US4)
- **SC-004**: No registration/login required ✅ (US1)
- **SC-005**: 100% encrypted storage in iCloud ✅ (US5)
- **SC-006**: Tokens recoverable after device loss ✅ (US5)
- **SC-007**: Search <100ms response ✅ (US2)
- **SC-008**: TOTP codes generate within 1s of rollover ✅ (Foundational)
- **SC-009**: Support 50 tokens without performance issues ✅ (US2 + Polish)
- **SC-010**: Sync mechanism clear to users ✅ (US4)

---

## Notes

- **[P] tasks** = different files, no dependencies, can run in parallel
- **[Story] label** maps task to specific user story for traceability
- **TDD Required**: All tests written FIRST, implementation follows (Constitution Principle I)
- **Each user story** should be independently completable and testable
- **Verify tests fail** before implementing (Red-Green-Refactor cycle)
- **Commit after each task** or logical group for clean git history
- **Stop at checkpoints** to validate story independently before proceeding
- **Physical device testing** required for Keychain sync, iCloud sync, camera
- **Avoid**: vague tasks, file conflicts, cross-story dependencies that break independence

---

**Total Tasks**: 98
**MVP Tasks (Setup + Foundational + US1)**: 44 tasks
**Estimated MVP Effort**: 2-3 weeks for experienced iOS developer following TDD
**Full Feature Effort**: 4-6 weeks with all user stories and polish

**Next Step**: Start with Phase 1 Setup (T001-T008) immediately
