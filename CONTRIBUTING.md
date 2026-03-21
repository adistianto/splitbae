# Contributing to SplitBae

SplitBae is licensed under the **[Apache License 2.0](LICENSE)**. Contributions you merge are under that license. When adding **dependencies** (Dart crates, Flutter plugins, Rust crates), prefer **Apache-2.0–compatible** licenses; flag **copyleft** or **proprietary** terms in PRs for review.

## Before you change code

1. Read **[`.cursorrules`](.cursorrules)** — architecture, MVP scope, and style expectations are defined there.
2. Prefer **small, vertical commits** (one logical change per commit) so history stays easy to bisect.

## Trunk-based workflow

- **`main`** is the integration branch; keep it **buildable** and **releasable**.
- Avoid long-lived feature branches. Merge or push to `main` often via short-lived branches or direct commits (team policy).
- Use **GitHub Issues** as the task list: **one issue per small feature** when it helps (e.g. “Add encrypted DB”, “Backup export UI”).

## Project-specific commands

| Task | Command |
|------|---------|
| Dependencies | `flutter pub get` |
| Localization codegen | `flutter gen-l10n` (or automatic with `flutter pub get` when ARBs change) |
| Drift (SQLite) codegen | `dart run build_runner build --delete-conflicting-outputs` after editing `lib/core/database/app_database.dart` |
| Unit tests (VM) | `flutter test` — DB smoke tests use `NativeDatabase.memory()` (plain SQLite, not SQLCipher) |
| Rust ↔ Dart bridge | From repo root: `flutter_rust_bridge_codegen generate` |
| Rust check | `cd rust && cargo check` |
| Analyze | `dart analyze` / `flutter analyze` |

After changing **`rust/src/api/`** or FRB types, regenerate the bridge **before** opening a PR.

## Local database (Drift + SQLCipher)

- **Schema**: `lib/core/database/app_database.dart` (versioned migrations). Generated code: `app_database.g.dart` (do not hand-edit). **v2** adds indexes on `participants(ledger_id)` and `receipt_lines(ledger_id, created_at_ms)` for list/FK workloads.
- **Prefs key**: `kEncryptDatabasePreferenceKey` in `lib/core/prefs_keys.dart` (shared by settings UI and `openAppDatabase`).
- **Encryption**: optional, via **SQLCipher** (`sqflite_sqlcipher`). When **Encrypt local database** is on, the passphrase is stored in **Flutter Secure Storage** (`splitbae_sqlcipher_passphrase_v1`), generated with **256 bits** of `Random.secure()` entropy (Base64URL). Turning encryption **off** removes that key from secure storage after the DB files are deleted.
- **Toggling encryption** in Settings shows a confirmation, then **persists the new flag**, **deletes** the SQLite files (including WAL/SHM), **reopens** the DB in the new mode, and **re-seeds** the default ledger. There is **no in-place re-key** yet—local bill data is intentionally wiped (secure-by-design: no mixed plain/encrypted file state).
- **Runtime swap**: `AppDatabaseController` (`lib/core/providers/database_providers.dart`) holds the active `AppDatabase` so the process does not need a full app restart after a successful toggle.

## Style

- Match existing layout and naming; see `.cursorrules` → *Repository layout*.
- No drive-by refactors mixed with feature work.
- Comments explain **why**, not what the code already says.

## Localization (crowdsourcing & machine translation)

**Source language**: **`lib/l10n/app_en.arb`** is the template. New UI strings are added **here first**, with optional `@key` metadata (`description`) so human translators and MT tools know **context** (screen, button vs error, constraints).

**Other locales**: `app_<languageCode>.arb` (e.g. `app_id.arb`) contain **only** the same keys and translated **values**—no need to duplicate `@` blocks in non-template files; Flutter merges metadata from the template.

### Crowdsourcing (GitHub)

1. Fork / branch, copy `app_en.arb` keys into a new file `app_<locale>.arb` with `"@@locale": "<code>"`.
2. Translate values (or fill from MT, then review).
3. Open a PR. Keep PRs **small** (one locale or one feature’s strings).
4. Run `flutter gen-l10n` and ensure `dart analyze` passes.

Optional: hook the repo to **Weblate**, **Crowdin**, or **Tolgee** with **ARB** export—same files, friendlier UI for reviewers.

### Machine translation (MT)

- **Workflow**: English ARB → MT → **human review** → merge. Do not ship raw MT for legal/sensitive strings without review.
- **Practical options**: paste JSON values into DeepL/Google Translate **per batch**; use your CAT tool’s ARB/JSON import; or a small script that reads `app_en.arb` and writes draft `app_xx.arb` (preserve keys and `@@locale`).
- **Glossary**: keep product name **SplitBae** and technical tokens (**IDR**, currency codes) consistent—add a one-line note in PR description when introducing new terms.

### Gap report

After adding keys to English, run `flutter gen-l10n`. The file **`l10n_untranslated.txt`** (repo root) lists strings **missing** in secondary ARBs—use it to prioritize translations.
