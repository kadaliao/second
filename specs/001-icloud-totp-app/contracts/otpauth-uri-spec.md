# otpauth:// URI Specification Contract

**Purpose**: Define the parsing contract for otpauth:// URIs used in QR codes for TOTP configuration.

**Standard**: Based on [Google Authenticator Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format)

## URI Format

```
otpauth://TYPE/LABEL?PARAMETERS
```

### Components

#### 1. Scheme
- **Value**: `otpauth://`
- **Required**: Yes
- **Validation**: Must be exactly "otpauth" (case-insensitive)

#### 2. Type
- **Value**: `totp` (Time-based OTP)
- **Required**: Yes
- **Validation**: Must be "totp" (case-insensitive)
- **Note**: "hotp" (Counter-based OTP) is NOT supported in this app

#### 3. Label
- **Format**: `issuer:account` or `account`
- **Required**: Yes
- **Components**:
  - `issuer`: Service name (e.g., "GitHub", "Google")
  - `account`: Username or email (e.g., "user@example.com")
- **Validation**:
  - URL-encoded (decoded with `removingPercentEncoding`)
  - If colon present, split into issuer and account
  - If no colon, entire label is account (issuer from query parameter)
- **Examples**:
  - `GitHub:user@example.com` → issuer="GitHub", account="user@example.com"
  - `user@example.com` → issuer="", account="user@example.com" (fallback to query parameter)
  - `Google%20Workspace:admin@company.com` → issuer="Google Workspace", account="admin@company.com"

#### 4. Query Parameters

| Parameter | Required | Default | Valid Values | Description |
|-----------|----------|---------|--------------|-------------|
| `secret` | Yes | N/A | Base32 (A-Z, 2-7, optional `=` padding) | Shared secret key |
| `issuer` | Recommended | "" | Any string | Service name (fallback if not in label) |
| `algorithm` | No | `SHA1` | `SHA1`, `SHA256`, `SHA512` | HMAC algorithm |
| `digits` | No | `6` | `6`, `8` | Number of digits in OTP code |
| `period` | No | `30` | Positive integer | Time step in seconds |

**Note**: All parameter names are case-sensitive (lowercase).

---

## Valid Examples

### Minimal URI (defaults)
```
otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP
```
**Parsed Result**:
- issuer: "GitHub"
- account: "user@example.com"
- secret: "JBSWY3DPEHPK3PXP"
- algorithm: "SHA1" (default)
- digits: 6 (default)
- period: 30 (default)

---

### Full URI (explicit parameters)
```
otpauth://totp/Google:user@gmail.com?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Google&algorithm=SHA1&digits=6&period=30
```
**Parsed Result**:
- issuer: "Google" (from label)
- account: "user@gmail.com"
- secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
- algorithm: "SHA1"
- digits: 6
- period: 30

---

### No issuer in label (fallback to parameter)
```
otpauth://totp/user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Amazon
```
**Parsed Result**:
- issuer: "Amazon" (from query parameter)
- account: "user@example.com"
- secret: "JBSWY3DPEHPK3PXP"
- algorithm: "SHA1" (default)
- digits: 6 (default)
- period: 30 (default)

---

### Custom algorithm and digits
```
otpauth://totp/Microsoft:user@outlook.com?secret=JBSWY3DPEHPK3PXP&issuer=Microsoft&algorithm=SHA256&digits=8
```
**Parsed Result**:
- issuer: "Microsoft"
- account: "user@outlook.com"
- secret: "JBSWY3DPEHPK3PXP"
- algorithm: "SHA256"
- digits: 8
- period: 30 (default)

---

### URL-encoded label
```
otpauth://totp/Google%20Workspace:admin%40company.com?secret=JBSWY3DPEHPK3PXP
```
**Parsed Result**:
- issuer: "Google Workspace" (decoded)
- account: "admin@company.com" (decoded)
- secret: "JBSWY3DPEHPK3PXP"
- algorithm: "SHA1" (default)
- digits: 6 (default)
- period: 30 (default)

---

## Invalid Examples (Must Reject)

### Missing secret parameter
```
otpauth://totp/GitHub:user@example.com
```
**Error**: `missingSecret` (secret parameter is required)

---

### Invalid scheme
```
http://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP
```
**Error**: `invalidScheme` (must be "otpauth://")

---

### Invalid type (hotp not supported)
```
otpauth://hotp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP
```
**Error**: `unsupportedType` (only "totp" supported)

---

### Invalid Base32 secret
```
otpauth://totp/GitHub:user@example.com?secret=INVALID!@#$
```
**Error**: `invalidSecret` (secret contains invalid Base32 characters)

---

### Invalid algorithm
```
otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&algorithm=MD5
```
**Error**: `unsupportedAlgorithm` (only SHA1, SHA256, SHA512 supported)

---

### Invalid digits
```
otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&digits=4
```
**Error**: `invalidDigits` (only 6 or 8 digits supported)

---

### Invalid period
```
otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&period=-30
```
**Error**: `invalidPeriod` (period must be positive integer)

---

## Parsing Logic (Swift)

```swift
struct OTPAuthURI {
    enum ParseError: Error {
        case invalidScheme
        case unsupportedType
        case missingSecret
        case invalidSecret
        case unsupportedAlgorithm
        case invalidDigits
        case invalidPeriod
    }

    static func parse(_ uri: String) throws -> Token {
        // 1. Parse URL
        guard let url = URL(string: uri),
              url.scheme?.lowercased() == "otpauth" else {
            throw ParseError.invalidScheme
        }

        // 2. Validate type
        guard url.host?.lowercased() == "totp" else {
            throw ParseError.unsupportedType
        }

        // 3. Parse label
        let label = url.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .removingPercentEncoding ?? ""
        let labelComponents = label.split(separator: ":", maxSplits: 1)

        let issuer: String
        let account: String

        if labelComponents.count == 2 {
            issuer = String(labelComponents[0])
            account = String(labelComponents[1])
        } else {
            issuer = "" // Will fallback to query parameter
            account = label
        }

        // 4. Parse query parameters
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            throw ParseError.missingSecret
        }

        guard let secret = queryItems.first(where: { $0.name == "secret" })?.value else {
            throw ParseError.missingSecret
        }

        // Validate Base32 secret
        guard Base32Decoder.isValid(secret) else {
            throw ParseError.invalidSecret
        }

        // Parse optional parameters with defaults
        let issuerParam = queryItems.first(where: { $0.name == "issuer" })?.value ?? ""
        let finalIssuer = issuer.isEmpty ? issuerParam : issuer

        let algorithmString = queryItems.first(where: { $0.name == "algorithm" })?.value ?? "SHA1"
        guard let algorithm = TOTPAlgorithm(rawValue: algorithmString) else {
            throw ParseError.unsupportedAlgorithm
        }

        let digitsString = queryItems.first(where: { $0.name == "digits" })?.value ?? "6"
        guard let digits = Int(digitsString), (digits == 6 || digits == 8) else {
            throw ParseError.invalidDigits
        }

        let periodString = queryItems.first(where: { $0.name == "period" })?.value ?? "30"
        guard let period = Int(periodString), period > 0 else {
            throw ParseError.invalidPeriod
        }

        // 5. Create Token
        return Token(
            issuer: finalIssuer,
            account: account,
            secret: secret,
            digits: digits,
            period: period,
            algorithm: algorithm
        )
    }
}
```

---

## Test Vectors

### Test Case 1: Minimal URI
**Input**:
```
otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP
```
**Expected Output**:
- issuer: "GitHub"
- account: "user@example.com"
- secret: "JBSWY3DPEHPK3PXP"
- digits: 6
- period: 30
- algorithm: .sha1

---

### Test Case 2: Full URI
**Input**:
```
otpauth://totp/Google:user@gmail.com?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Google&algorithm=SHA256&digits=8&period=60
```
**Expected Output**:
- issuer: "Google"
- account: "user@gmail.com"
- secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
- digits: 8
- period: 60
- algorithm: .sha256

---

### Test Case 3: URL-Encoded
**Input**:
```
otpauth://totp/Google%20Workspace:admin%40company.com?secret=JBSWY3DPEHPK3PXP
```
**Expected Output**:
- issuer: "Google Workspace"
- account: "admin@company.com"
- secret: "JBSWY3DPEHPK3PXP"
- digits: 6
- period: 30
- algorithm: .sha1

---

### Test Case 4: No issuer in label
**Input**:
```
otpauth://totp/user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Amazon
```
**Expected Output**:
- issuer: "Amazon"
- account: "user@example.com"
- secret: "JBSWY3DPEHPK3PXP"
- digits: 6
- period: 30
- algorithm: .sha1

---

### Test Case 5: Invalid secret (should throw)
**Input**:
```
otpauth://totp/GitHub:user@example.com?secret=INVALID!@#$
```
**Expected**: Throws `ParseError.invalidSecret`

---

### Test Case 6: Missing secret (should throw)
**Input**:
```
otpauth://totp/GitHub:user@example.com
```
**Expected**: Throws `ParseError.missingSecret`

---

### Test Case 7: Unsupported type (should throw)
**Input**:
```
otpauth://hotp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP
```
**Expected**: Throws `ParseError.unsupportedType`

---

## Validation Rules Summary

- **Scheme**: Must be "otpauth"
- **Type**: Must be "totp"
- **Secret**: Required, must be valid Base32 (A-Z, 2-7, optional padding)
- **Issuer**: Optional, can be in label or query parameter
- **Account**: Required, extracted from label
- **Algorithm**: Optional, default "SHA1", valid values: SHA1, SHA256, SHA512
- **Digits**: Optional, default 6, valid values: 6, 8
- **Period**: Optional, default 30, must be positive integer

---

## Compatibility Notes

- This implementation follows the Google Authenticator Key URI Format specification
- Compatible with QR codes generated by most services (Google, GitHub, Microsoft, etc.)
- Does NOT support HOTP (counter-based OTP) - only TOTP
- Does NOT support custom parameters beyond the standard specification
- URL encoding/decoding handled automatically by Swift's URL APIs

---

**Contract Status**: ✅ DEFINED
**Version**: 1.0.0
**Last Updated**: 2026-01-15
