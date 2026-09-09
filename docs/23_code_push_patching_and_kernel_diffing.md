# 23. Code Push Patching & Kernel Diffing Mechanics

## 1. Overview of Code Push OTA Pipeline

DartNative includes an integrated Over-The-Air (OTA) Code Push architecture (`dn release` / `dn patch`).

Unlike WebViews or JavaScript bundle reloaders, DartNative performs **Byte-Level Dart Kernel (`.dill`) AST Diffing** against baseline release binaries.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Code Push Release Lifecycle                     │
├────────────────────────────────────────────────────────────────────────┤
│ 1. `dn release ios`                                                    │
│    - Compiles baseline AOT Kernel AST (`.dn_code_push/release.kernel`)│
│    - Writes version metadata file (`lib/dn_release_version.g.dart`)   │
│    - Registers release hash with private registry (`dartpub.dev`)      │
│                                                                        │
│ 2. Bugfix Applied in Code                                              │
│                                                                        │
│ 3. `dn patch ios`                                                      │
│    - Compiles new Kernel AST (`patch.kernel`)                          │
│    - Computes minimal binary AST delta (`release.kernel` vs `patch.kernel`)│
│    - Signs patch payload using Ed25519 private key                      │
│    - Deploys `.patch` payload to OTA server                            │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Kernel AST Differential Engine Mechanics

1. **AST Node Comparison**: The `code_push` tool parses the Dart Kernel AST (Abstract Syntax Tree) representations of both the baseline release and the modified source.
2. **Delta Generation**:
   - Unmodified class definitions, constants, and libraries are stripped from the patch payload.
   - Only modified method bodies, updated string tables, and new class definitions are serialized into the `.patch` bundle.
   - Patch payloads are compressed (typically **< 150 KB** for typical bug fixes).
3. **Client-Side Loading Lifecycle**:
   - On app launch, the embedded DartVM checks `https://dartpub.dev` for published patches matching `dnReleaseVersion`.
   - Downloads and verifies Ed25519 signature.
   - The Dart VM loads the delta patch into memory, replacing function pointers dynamically before mounting root UI elements.

---

## 3. Rollback Safety & Version Guardrails

To prevent app crashes from bad patches:
- **Crash Guard**: If an app crashes during startup immediately after loading a patch, DartNative marks the active patch as corrupted and automatically rolls back to the native release baseline on the next launch.
