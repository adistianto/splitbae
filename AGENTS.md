# AGENTS.md

## Cursor Cloud specific instructions

### Overview

SplitBae is an offline-first Flutter + Rust bill-splitting app. There are no backend services, Docker containers, or external APIs. The two main build targets are:

| Component | Language | Commands |
|-----------|----------|----------|
| **Flutter app** (`lib/`) | Dart/Flutter | `flutter pub get`, `flutter test`, `dart analyze lib/ test/` |
| **Rust core** (`rust/`) | Rust | `cargo check`, `cargo test` |

Standard commands for linting, testing, and codegen are documented in `CONTRIBUTING.md` ("Project-specific commands" table).

### Non-obvious notes

- **Flutter 3.41.5+ required** (Dart SDK `^3.11.3`). The SDK is installed at `/opt/flutter/bin` and added to `PATH` via `~/.bashrc`.
- **Rust stable** toolchain via `rustup` (edition 2021, FRB 2.11.1 pinned).
- **`dart analyze`** at the repo root reports ~40 errors in `rust_builder/cargokit/build_tool/` (third-party Cargokit code with unresolved `pub` deps). These are pre-existing and not actionable. **Always scope analysis to project code**: `dart analyze lib/ test/`.
- **Linux desktop build** requires `ninja-build`, `libgtk-3-dev`, `g++-14`, `lld`, and `llvm` system packages, plus a `libstdc++.so` symlink (`/usr/lib/x86_64-linux-gnu/libstdc++.so -> /usr/lib/gcc/x86_64-linux-gnu/13/libstdc++.so`). These are already installed in the VM snapshot.
- **Linux desktop runtime limitation**: The app binary builds and launches, but crashes before rendering the UI because `sqflite_sqlcipher` has **no Linux desktop plugin**. The `MissingPluginException` on `com.davidmartos96.sqflite_sqlcipher` is expected. This does not affect `flutter test` (tests use `NativeDatabase.memory()`), Rust tests, or analysis.
- **Localization codegen** (`flutter gen-l10n`) is triggered automatically by `flutter pub get` when `flutter: generate: true` is set in `pubspec.yaml`. Explicit `flutter gen-l10n` is needed only if ARB files changed without running `pub get`.
- **Drift codegen**: Generated file `app_database.g.dart` is committed. Run `dart run build_runner build --delete-conflicting-outputs` only after editing `lib/core/database/app_database.dart`.
- **FRB codegen**: Run `flutter_rust_bridge_codegen generate` from repo root only after changing `#[flutter_rust_bridge::frb]` APIs in `rust/src/api/`.
