# SplitBae

Offline-first bill splitting that feels fast, private, and “native where it matters”.

## Why SplitBae?

SplitBae is built as a **Perfect Local Utility**:

- **Offline-first by design**: your bill data lives locally (SQLite via Drift, with an optional SQLCipher layer).
- **Encrypted local storage**: when encryption is enabled, sensitive data is protected at rest.
- **Native OCR for Snap & Split**: extract receipt line candidates using on-device OCR (ML Kit on Android, Vision on iOS), then let users correct directly in the UI.
- **Rust-speed math**: deterministic currency rules and split calculations live in Rust and are exposed to Flutter via `flutter_rust_bridge`.

Instead of outsourcing receipt understanding to a cloud LLM, SplitBae keeps the core workflow private, fast, and editable.

## Key Features

- **Snap & Split (Native OCR)**: take a photo or choose from the gallery, run on-device text recognition, parse candidate lines, and edit before saving. Native OCR failures never block manual entry.
- **Encrypted Local Storage (SQLCipher)**: at-rest encryption with a safe migration path and clear user controls.
- **Rust-Speed Math**: all business logic and currency math are implemented in Rust (`rust/src/api/simple.rs`) and consumed by Flutter.
- **Per-line assignment**: each receipt line can be split among a chosen subset of participants (empty assignment means “everyone”).
- **Manual backups**: export or import a `.sb_backup` file from Settings so users can move local data safely.

## Technical Architecture

SplitBae keeps responsibilities sharp:

- **Rust** owns deterministic rules. Flutter delegates split math and money encoding/decoding to Rust via `flutter_rust_bridge`.
- **Flutter** focuses on UX, state orchestration (Riverpod), persistence (Drift), and calling the native OCR platform channels.

### Rust ↔ Flutter bridge

`flutter_rust_bridge` matters because it gives you a reviewable, typed boundary:

- Rust stays unit-testable and deterministic for correctness.
- Flutter stays responsive by offloading compute-sensitive logic to Rust.
- Contributors can reason about “what changed” by looking at explicit FRB surfaces (`#[flutter_rust_bridge::frb]`).

## Monorepo

This repository is intentionally **single-repo**:

- `lib/` is the Flutter app
- `rust/` is the Rust core (split logic exposed via FRB)

Keeping both parts together makes it harder for behavior to drift between UI and math.

## Getting Started

### Prerequisites

- Flutter (stable)
- Rust toolchain (`rustup`) for `rust/`

### Setup

```bash
flutter pub get
flutter gen-l10n

cd rust && cargo check && cd ..

# if you changed Rust FRB API (types/functions annotated with #[flutter_rust_bridge::frb])
flutter_rust_bridge_codegen generate

flutter run
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

[Apache License 2.0](LICENSE). By contributing, you agree your contributions are under the same license.
