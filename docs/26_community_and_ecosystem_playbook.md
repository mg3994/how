# 26. Community & Ecosystem Plugin Publishing Playbook

## 1. Authoring Community FFI Plugins

The DartNative ecosystem relies on high-performance C-ABI FFI plugins hosted on `https://dartpub.dev`.

### Ecosystem Plugin Principles
1. **Zero MethodChannels**: Never use legacy `MethodChannel` binary messengers. All platform calls must execute via direct C-ABI FFI function pointers (`DynamicLibrary`).
2. **Synchronous Execution Where Possible**: Queries that return immediate native state (e.g. device battery, system theme, hardware capabilities) should execute synchronously.
3. **Isolate Ports for Async Events**: Use `Dart_PostCObject` with native port IDs for continuous streams (e.g. sensor telemetry, audio PCM streams).

---

## 2. Plugin Publishing Workflow (`dn publish`)

Publishing a third-party plugin package to `dartpub.dev` requires a valid developer publish token (`dnp_…`).

```bash
# 1. Configure private registry publish token
dn config --publish-token "dnp_live_secret_token_12345"

# 2. Run dry-run verification checks
dn plugin dry-run

# 3. Publish plugin to dartpub.dev
dn publish
```

---

## 3. `pubspec.yaml` Schema for Ecosystem Plugins

```yaml
name: my_community_plugin
description: A high-performance community FFI plugin for DartNative.
version: 1.0.0
homepage: https://dartpub.dev/packages/my_community_plugin

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  dartnative: ^1.0.0

# DartNative plugin manifest definition
dartnative:
  plugin:
    platforms:
      ios:
        pluginClass: MyCommunityPlugin
      android:
        package: com.example.my_community_plugin
        pluginClass: MyCommunityPlugin
```
