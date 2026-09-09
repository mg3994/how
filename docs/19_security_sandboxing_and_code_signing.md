# 19. Security, Sandboxing & Code Signing Architecture

## 1. Security Architecture & Sandboxing

DartNative applications operate within full OS application sandbox boundaries on both iOS and Android.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   App Sandbox Boundary (iOS / Android)                │
│                                                                        │
│  ┌─────────────────────────┐           ┌────────────────────────────┐  │
│  │   Dart AOT Runtime      │           │   Native C++ Engine / Yoga │  │
│  │   (Dart VM Memory)      │──────────>│   (Native UIKit Views)     │  │
│  └─────────────────────────┘           └────────────────────────────┘  │
│               │                                      │                 │
│               ▼                                      ▼                 │
│  ┌─────────────────────────┐           ┌────────────────────────────┐  │
│  │ Encrypted SQLite DB     │           │ OS Hardware Security Vault │  │
│  │ (dartnative_sqlite)     │           │ (Keychain / Keystore)      │  │
│  └─────────────────────────┘           └────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Hardware Security Storage (`dartnative_secure_storage`)

Sensitve data (JWT auth tokens, private API keys, cryptographic secrets) are stored using hardware-backed security modules:
- **iOS**: Bound to Apple **Keychain Services** (`SecItemAdd` / `SecItemCopyMatching`) backed by the Secure Enclave.
- **Android**: Bound to **Android KeyStore System** backed by `EncryptedSharedPreferences` using AES-256 GCM encryption keys generated in hardware TEE (Trusted Execution Environment).

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_secure_storage/dartnative_secure_storage.dart';

// Write sensitive secret
await SecureStorage.write(key: 'auth_token', value: 'jwt_secret_token_12345');

// Read secret securely
final token = await SecureStorage.read(key: 'auth_token');
```

---

## 3. Code Push Security & Patch Verification

Over-the-Air (OTA) Code Push patches (`dn patch`) represent a potential attack vector if unverified. DartNative enforces cryptographic patch signature verification:

1. **Ed25519 Cryptographic Signing**: When `dn patch` compiles a kernel diff payload, it signs the patch file using the developer's private signing key.
2. **Runtime Signature Verification**: Before applying a downloaded `.patch` payload, the DartNative client app verifies the digital signature against the developer's embedded public key. Unsigned or tampered patches are discarded immediately.
