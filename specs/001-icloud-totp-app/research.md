# Research: iCloud-Synced 2FA (TOTP) Application

**Feature**: 001-icloud-totp-app
**Date**: 2026-01-15
**Status**: Phase 0 Complete

## Purpose

This document resolves all technical unknowns identified in plan.md Technical Context, researches best practices for chosen technologies, and documents decisions with rationale.

## Research Tasks

### 1. iCloud Sync Mechanism: CloudKit vs NSUbiquitousKeyValueStore

**Unknown**: Which iCloud sync mechanism should be used for encrypted vault storage?

#### Decision: NSUbiquitousKeyValueStore (Key-Value Store)

**Rationale**:

- **Simplicity**: NSUbiquitousKeyValueStore is a simple key-value API ideal for small amounts of data (<1MB). Our encrypted vault for 50 tokens will be ~50-100KB, well within limits.
- **Automatic Sync**: System handles sync automatically; no need to manage CKRecord operations, conflict resolution, or subscriptions.
- **Lower Complexity**: Fits Constitution Principle IV (Simplicity). CloudKit adds unnecessary abstraction (CKContainer, CKDatabase, CKRecord, zones, subscriptions) for our use case.
- **Testing**: Easier to mock and test; no need for CloudKit test environment setup.
- **User Experience**: Transparent sync without user-facing CloudKit account checks or error states.
- **Performance**: Sufficient for our needs; sync typically completes within 5-10 seconds under normal network conditions (meets SC-003).

**Alternatives Considered**:

- **CloudKit (Private Database)**: More powerful, supports structured queries, relationships, and large binary assets. However, adds significant complexity:
  - Requires CKContainer setup, schema design, CKRecord CRUD operations
  - Manual conflict resolution (CKRecord versioning)
  - More verbose API (fetch/save operations vs simple get/set)
  - Overkill for single-file encrypted blob storage
  - Rejected: Violates simplicity principle for no tangible benefit

- **iCloud Drive (NSFileCoordinator + NSFilePresenter)**: File-based sync with conflict handling. Considered but rejected:
  - More complex than KVStore for small data
  - Requires file coordination and presenter delegate methods
  - Better suited for document-based apps
  - Rejected: Adds file management complexity

#### Implementation Details

**NSUbiquitousKeyValueStore API**:
```swift
// Set encrypted vault
NSUbiquitousKeyValueStore.default.set(encryptedData, forKey: "vault")
NSUbiquitousKeyValueStore.default.synchronize()

// Read encrypted vault
let encryptedData = NSUbiquitousKeyValueStore.default.data(forKey: "vault")

// Observe changes
NotificationCenter.default.addObserver(
    forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
    object: NSUbiquitousKeyValueStore.default,
    queue: .main
) { notification in
    // Handle remote changes
}
```

**Limits**:
- Max total storage: 1MB across all keys
- Max per-key value: 1MB (more than sufficient for encrypted vault)
- Max number of keys: 1024

**Entitlements Required**:
- `com.apple.developer.ubiquity-kvstore-identifier`: $(TeamIdentifierPrefix)$(CFBundleIdentifier)

---

### 2. TOTP Implementation Best Practices (RFC 6238)

**Research Area**: Best practices for implementing TOTP in Swift using CryptoKit

#### Key Findings

**TOTP Formula (RFC 6238)**:
```
TOTP = HOTP(K, T)
where T = (Current Unix Time - T0) / X
```
- K: Shared secret key (Base32 decoded)
- T0: Unix epoch (0)
- X: Time step (default 30 seconds)
- HOTP: HMAC-based OTP (RFC 4226)

**HMAC Algorithms**:
- SHA1 (default, most common)
- SHA256 (supported by some services)
- SHA512 (supported by some services)

**CryptoKit Implementation**:
```swift
import CryptoKit

func generateTOTP(secret: Data, time: Date, digits: Int, period: Int, algorithm: TOTPAlgorithm) -> String {
    let counter = UInt64(time.timeIntervalSince1970) / UInt64(period)
    let counterData = withUnsafeBytes(of: counter.bigEndian) { Data($0) }

    let hmac: Data
    switch algorithm {
    case .sha1:
        let key = SymmetricKey(data: secret)
        hmac = Data(HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key))
    case .sha256:
        let key = SymmetricKey(data: secret)
        hmac = Data(HMAC<SHA256>.authenticationCode(for: counterData, using: key))
    case .sha512:
        let key = SymmetricKey(data: secret)
        hmac = Data(HMAC<SHA512>.authenticationCode(for: counterData, using: key))
    }

    // Dynamic truncation (RFC 4226 Section 5.3)
    let offset = Int(hmac.last! & 0x0f)
    let truncatedHash = hmac.subdata(in: offset..<offset+4)
    var number = truncatedHash.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
    number &= 0x7fffffff // Clear most significant bit

    let otp = number % UInt32(pow(10, Double(digits)))
    return String(format: "%0\(digits)d", otp)
}
```

**Test Vectors (RFC 6238 Appendix B)**:
- Secret: "12345678901234567890" (Base32: GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ)
- Time: 1970-01-01 00:00:59 UTC → TOTP: 94287082 (SHA1, 8 digits)
- Time: 2005-03-18 01:58:29 UTC → TOTP: 07081804 (SHA1, 8 digits)

**Best Practices**:
- Use `Insecure.SHA1` from CryptoKit (marked insecure for general crypto, but RFC 6238 mandates it for TOTP)
- Handle endianness correctly: counter must be big-endian
- Zero-pad OTP codes to specified digit length
- Validate time drift: allow ±1 time step for clock skew tolerance (not implemented in app, but noted for future)
- Use `Date()` for current time; avoid manual Unix timestamp calculations

---

### 3. Base32 Decoding for TOTP Secrets

**Research Area**: Base32 encoding/decoding for TOTP secret keys

#### Key Findings

**Base32 Alphabet (RFC 4648)**:
- Standard alphabet: `ABCDEFGHIJKLMNOPQRSTUVWXYZ234567`
- Padding character: `=` (optional in some implementations)
- Case-insensitive (often uppercase in QR codes)

**Swift Implementation**:
- No built-in Base32 decoder in Foundation or CryptoKit
- Options:
  1. Implement RFC 4648 Base32 decoder (lightweight, 50-100 lines)
  2. Use third-party SPM package (violates "no dependencies" principle)

**Decision**: Implement custom Base32 decoder

**Rationale**:
- Simple algorithm (~80 lines including validation)
- Zero dependencies (aligns with Constitution Principle III)
- Full control over error handling
- Easy to test with RFC 4648 test vectors

**Implementation Sketch**:
```swift
struct Base32Decoder {
    private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

    static func decode(_ encoded: String) throws -> Data {
        let cleaned = encoded.uppercased().replacingOccurrences(of: "=", with: "")
        var bits = ""

        for char in cleaned {
            guard let index = alphabet.firstIndex(of: char) else {
                throw Base32Error.invalidCharacter(char)
            }
            let binary = String(alphabet.distance(from: alphabet.startIndex, to: index), radix: 2)
            bits += String(repeating: "0", count: 5 - binary.count) + binary
        }

        var bytes = [UInt8]()
        for i in stride(from: 0, to: bits.count, by: 8) {
            let end = min(i + 8, bits.count)
            let byte = bits[bits.index(bits.startIndex, offsetBy: i)..<bits.index(bits.startIndex, offsetBy: end)]
            if byte.count == 8, let value = UInt8(byte, radix: 2) {
                bytes.append(value)
            }
        }

        return Data(bytes)
    }
}
```

**Test Vectors (RFC 4648)**:
- "" → ""
- "MY======" → "f"
- "MZXQ====" → "fo"
- "MZXW6===" → "foo"
- "MZXW6YQ=" → "foob"
- "MZXW6YTB" → "fooba"
- "MZXW6YTBOI======" → "foobar"

---

### 4. AES-GCM Encryption with CryptoKit

**Research Area**: Best practices for AES-GCM encryption/decryption using CryptoKit

#### Key Findings

**CryptoKit AES.GCM API**:
```swift
import CryptoKit

// Encryption
let key = SymmetricKey(size: .bits256) // Generate once, store in Keychain
let plaintext = Data("vault content".utf8)
let sealedBox = try AES.GCM.seal(plaintext, using: key)

// SealedBox contains: nonce + ciphertext + tag
let combined = sealedBox.combined // All-in-one Data representation

// Decryption
let sealedBox = try AES.GCM.SealedBox(combined: combined)
let decrypted = try AES.GCM.open(sealedBox, using: key)
```

**Best Practices**:
- **Key Size**: Use 256-bit keys (`SymmetricKey.init(size: .bits256)`)
- **Nonce**: CryptoKit auto-generates unique nonce per encryption (12 bytes)
- **Authentication Tag**: 16 bytes, automatically verified during decryption
- **Combined Representation**: Use `sealedBox.combined` for storage (nonce + ciphertext + tag in single Data blob)
- **Key Generation**: Generate once on first launch; store in Keychain with `kSecAttrSynchronizable = true`
- **Error Handling**: `AES.GCM.open()` throws `CryptoKitError.authenticationFailure` if tag verification fails (tampering detected)

**Vault Structure**:
```json
{
  "tokens": [
    {"issuer": "GitHub", "account": "user@example.com", "secret": "BASE32SECRET", ...}
  ],
  "version": 1
}
```
1. Serialize to JSON → Data
2. Encrypt with AES-GCM → SealedBox.combined
3. Store combined Data in NSUbiquitousKeyValueStore

**Security Properties**:
- **Confidentiality**: AES-256 encryption (quantum-resistant for practical purposes)
- **Integrity**: GCM authentication tag prevents tampering
- **Authenticated Encryption**: Provides both confidentiality and authenticity
- **No IV Reuse**: CryptoKit ensures unique nonces per encryption

---

### 5. Keychain Storage with iCloud Keychain Sync

**Research Area**: Best practices for storing vault key in Keychain with cross-device sync

#### Key Findings

**Keychain Query for Synchronizable Key**:
```swift
// Save key
let key = SymmetricKey(size: .bits256)
let keyData = key.withUnsafeBytes { Data($0) }

let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "vaultKey",
    kSecAttrService as String: "com.second.totp",
    kSecValueData as String: keyData,
    kSecAttrSynchronizable as String: true, // Enable iCloud Keychain sync
    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock // Available after device unlock
]

let status = SecItemAdd(query as CFDictionary, nil)

// Retrieve key
var query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "vaultKey",
    kSecAttrService as String: "com.second.totp",
    kSecReturnData as String: true,
    kSecAttrSynchronizable as String: true
]

var item: CFTypeRef?
let status = SecItemCopyMatching(query as CFDictionary, &item)
if status == errSecSuccess, let keyData = item as? Data {
    let key = SymmetricKey(data: keyData)
}
```

**Key Attributes**:
- **kSecAttrSynchronizable**: `true` for cross-device sync via iCloud Keychain
- **kSecAttrAccessible**: `kSecAttrAccessibleAfterFirstUnlock` (available after device unlock, survives reboots, syncs to iCloud)
- **kSecAttrAccount**: Unique identifier ("vaultKey")
- **kSecAttrService**: App-specific service identifier ("com.second.totp")
- **kSecClass**: `kSecClassGenericPassword` (generic password item)

**Best Practices**:
- **First Launch**: Check if key exists; if not, generate and save
- **Key Recovery**: If encrypted vault exists in iCloud but key is missing from Keychain, show error state (FR-022, FR-023)
- **Deletion**: Never delete the key unless user explicitly uninstalls app and clears iCloud data
- **Testing**: Test on physical devices (Keychain sync doesn't work reliably in simulator)
- **Error Handling**: Handle `errSecItemNotFound`, `errSecDuplicateItem`, `errSecAuthFailed`

**iCloud Keychain Requirements**:
- User must have iCloud Keychain enabled in Settings → Apple ID → iCloud → Keychain
- Two-factor authentication required for Apple ID
- Keychain sync may take 5-30 seconds to propagate to other devices

**Security Properties**:
- Keys stored in Secure Enclave (hardware-backed on modern devices)
- Encrypted at rest with device passcode
- Synced encrypted to iCloud (Apple cannot decrypt without device passcode)
- Sandboxed per-app (other apps cannot access)

---

### 6. QR Code Scanning with AVFoundation

**Research Area**: Best practices for scanning otpauth:// QR codes using AVFoundation

#### Key Findings

**AVCaptureSession Setup**:
```swift
import AVFoundation

let captureSession = AVCaptureSession()
guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)

if captureSession.canAddInput(videoInput) {
    captureSession.addInput(videoInput)
}

let metadataOutput = AVCaptureMetadataOutput()
if captureSession.canAddOutput(metadataOutput) {
    captureSession.addOutput(metadataOutput)
    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    metadataOutput.metadataObjectTypes = [.qr]
}

captureSession.startRunning()
```

**QR Code Delegate**:
```swift
func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
       metadataObject.type == .qr,
       let stringValue = metadataObject.stringValue {
        // Parse otpauth:// URI
        parseOTPAuthURI(stringValue)
    }
}
```

**SwiftUI Integration**:
```swift
struct QRCodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?

    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let controller = QRCodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode)
    }

    class Coordinator: NSObject, QRCodeScannerDelegate {
        @Binding var scannedCode: String?

        init(scannedCode: Binding<String?>) {
            _scannedCode = scannedCode
        }

        func didScanCode(_ code: String) {
            scannedCode = code
        }
    }
}
```

**Camera Permission**:
- Add `NSCameraUsageDescription` to Info.plist
- Request permission: `AVCaptureDevice.requestAccess(for: .video)`
- Handle denied state gracefully

**Best Practices**:
- Stop capture session after successful scan
- Provide torch toggle for low-light environments
- Show framing guide overlay
- Validate otpauth:// URI format immediately after scan

---

### 7. otpauth:// URI Format (Google Authenticator Standard)

**Research Area**: otpauth:// URI specification for TOTP parameters

#### Key Findings

**URI Format**:
```
otpauth://totp/{issuer}:{account}?secret={base32secret}&issuer={issuer}&algorithm={SHA1|SHA256|SHA512}&digits={6|8}&period={30}
```

**Components**:
- **Scheme**: `otpauth://`
- **Type**: `totp` (Time-based OTP)
- **Label**: `{issuer}:{account}` or just `{account}`
- **Parameters**:
  - `secret`: Base32-encoded secret (required)
  - `issuer`: Service name (optional but recommended)
  - `algorithm`: SHA1 (default), SHA256, SHA512
  - `digits`: 6 (default), 8
  - `period`: 30 (default), custom values supported

**Examples**:
```
otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub
otpauth://totp/Google:user@gmail.com?secret=JBSWY3DPEHPK3PXP&issuer=Google&algorithm=SHA1&digits=6&period=30
otpauth://totp/Amazon?secret=JBSWY3DPEHPK3PXP&digits=8&algorithm=SHA256
```

**Parsing Logic**:
```swift
func parseOTPAuthURI(_ uri: String) throws -> Token {
    guard let url = URL(string: uri), url.scheme == "otpauth", url.host == "totp" else {
        throw OTPAuthError.invalidScheme
    }

    let label = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let components = label.split(separator: ":", maxSplits: 1)
    let issuer: String
    let account: String

    if components.count == 2 {
        issuer = String(components[0])
        account = String(components[1])
    } else {
        issuer = ""
        account = label
    }

    guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
        throw OTPAuthError.missingQueryParameters
    }

    guard let secret = queryItems.first(where: { $0.name == "secret" })?.value else {
        throw OTPAuthError.missingSecret
    }

    let algorithm = TOTPAlgorithm(rawValue: queryItems.first(where: { $0.name == "algorithm" })?.value ?? "SHA1") ?? .sha1
    let digits = Int(queryItems.first(where: { $0.name == "digits" })?.value ?? "6") ?? 6
    let period = Int(queryItems.first(where: { $0.name == "period" })?.value ?? "30") ?? 30

    return Token(issuer: issuer, account: account, secret: secret, digits: digits, period: period, algorithm: algorithm)
}
```

**Edge Cases**:
- URL-encoded special characters in issuer/account (decode with `removingPercentEncoding`)
- Missing issuer in label (use query parameter fallback)
- Invalid Base32 secret (validate during parsing)
- Unsupported algorithm/digits/period (use defaults or reject)

---

## Summary of Decisions

### Technology Choices

| Component | Decision | Rationale |
|-----------|----------|-----------|
| **iCloud Sync** | NSUbiquitousKeyValueStore | Simple, automatic, <1MB limit sufficient, no CloudKit complexity |
| **Encryption** | AES-GCM via CryptoKit | Native, audited, authenticated encryption, easy API |
| **Key Storage** | Keychain with kSecAttrSynchronizable | Cross-device sync, hardware-backed, sandboxed |
| **TOTP Generation** | CryptoKit HMAC (SHA1/256/512) | RFC 6238 compliant, native, testable |
| **Base32 Decoding** | Custom implementation (RFC 4648) | Zero dependencies, simple, testable |
| **QR Scanning** | AVFoundation AVCaptureSession | Native, standard iOS pattern, well-documented |
| **UI Framework** | SwiftUI | Declarative, testable, modern, aligns with constitution |
| **Concurrency** | async/await | Structured concurrency, no completion handlers |
| **Testing** | XCTest | Native, integrated with Xcode, supports TDD |

### Best Practices Summary

1. **TOTP Generation**:
   - Use CryptoKit HMAC with correct algorithm mapping
   - Implement dynamic truncation per RFC 4226
   - Test with RFC 6238 Appendix B test vectors
   - Handle big-endian counter encoding

2. **Encryption**:
   - Use AES.GCM.seal() with auto-generated nonces
   - Store SealedBox.combined representation
   - Verify authentication tag during decryption
   - Generate 256-bit key once on first launch

3. **Keychain**:
   - Set kSecAttrSynchronizable=true for sync
   - Use kSecAttrAccessibleAfterFirstUnlock
   - Handle key-not-found errors gracefully
   - Test on physical devices (not simulator)

4. **iCloud Sync**:
   - Observe NSUbiquitousKeyValueStore.didChangeExternallyNotification
   - Call synchronize() after writes (best practice, though system auto-syncs)
   - Handle conflicts (last-write-wins for our use case)
   - Stay under 1MB total storage

5. **QR Scanning**:
   - Request camera permission explicitly
   - Stop session after successful scan
   - Validate otpauth:// URI format immediately
   - Provide user feedback for invalid codes

6. **Error Handling**:
   - Log errors without exposing secrets
   - Provide clear user-facing messages
   - Handle missing Keychain key (iCloud Keychain disabled)
   - Handle network unavailable (offline mode)

### Open Questions (None)

All technical unknowns have been resolved. No blocking issues identified.

---

**Phase 0 Status**: ✅ COMPLETE
**Next Phase**: Phase 1 - Generate data-model.md, contracts/, quickstart.md
