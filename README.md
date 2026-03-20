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

## Contributing

See **[`CONTRIBUTING.md`](CONTRIBUTING.md)** (trunk-based workflow, Issues, codegen).

## License

[Apache License 2.0](LICENSE). By contributing, you agree your contributions are under the same license.
