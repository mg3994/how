# 30. Future Roadmap & Sunset Commitment Developer Handbook

## 1. Engine Roadmap & Architectural Horizon

DartNative continues to advance native cross-platform performance across key architectural frontiers:

1. **Expanded Native View Controls**: Bringing native desktop view targets (macOS AppKit and Windows WinUI 3) to the single-thread Yoga flexbox layout model.
2. **Enhanced On-Device AI Integrations**: Deeper execution graphs for `dartnative_onnxruntime` utilizing Apple Neural Engine (ANE) and Android NNAPI/NPU hardware accelerators.
3. **Advanced Web Assembly (Wasm) AOT Support**: Compiling DartNative view reconcilers into Wasm WebGPU modules for near-native web execution.

---

## 2. Section 4 Sunset Commitment: Developer Legal Handbook

Section 4 of the **DartNative Framework License** provides a legally binding open-source safety net for all active commercial license holders.

### Section 4 Legal Provisions Summary
- **Discontinuation Trigger**: Software is legally classified as "Discontinued" upon formal public notice by Licensor (Presence Network Inc.) OR upon expiration of **12 continuous months** without published updates or fix releases.
- **Mandatory 90-Day BSD 3-Clause Source Release**: Within 90 days of Discontinuation, Presence Network Inc. is legally obligated to release the full, current source code of the DartNative framework and all First-Party Plugins under the open-source **BSD 3-Clause License**.
- **Shipped Application Continuity**: Section 2(c) guarantees that applications already built and distributed to end-users remain permanently licensed to run without interruption even after subscription expiration.

---

## 3. Licensee Rights & Activation Procedures

In the event of a Discontinuation trigger:
1. **Source Access**: Active token holders gain access to the full C++ engine source code, Zero runtime, and FFI plugin repositories.
2. **Third-Party Component Independence**: Third-party open-source components (Yoga, Flutter Zero, Dart SDK, Skia) remain under their existing BSD 3-Clause or MIT licenses and continue operating independently.
3. **Self-Hosted Infrastructure**: Developers can compile `dn` CLI tools and host private package registries independently without depending on `dartpub.dev` servers.
