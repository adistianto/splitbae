# SplitBae

Offline-first bill splitting (**Splid × Splitty**): Flutter UI, **Rust** logic via **flutter_rust_bridge**, **Riverpod** state. See **[`.cursorrules`](.cursorrules)** for architecture, MVP (“Perfect Local Utility”), and design direction (Material 3 Expressive vs Liquid Glass).

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- [Rust](https://rustup.rs/) (for `rust/`)

## Quick start

```bash
flutter pub get
flutter gen-l10n
cd rust && cargo check && cd ..
flutter_rust_bridge_codegen generate   # if you changed Rust FRB API
flutter run
```

## Local data & encryption

Bill lines and participants live in an on-device **Drift** database with optional **SQLCipher**. **Settings → Backup** exports a plain JSON **`.sb_backup`** (share sheet) or imports one to replace local data—treat files like sensitive documents. Encryption migration and DB details are in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Contributing

See **[`CONTRIBUTING.md`](CONTRIBUTING.md)** (trunk-based workflow, Issues, codegen).

## License

[Apache License 2.0](LICENSE). By contributing, you agree your contributions are under the same license.
