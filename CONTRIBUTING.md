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
- **Toggling encryption** copies all rows into memory (`LocalDatabaseSnapshot`), recreates the on-disk file in the new mode (plain vs SQLCipher), imports rows back, then runs `ensureSeedData` only if needed (empty DB). On failure, files are cleared, the previous encryption flag is restored, and the snapshot is written back—users see a non-fatal snackbar if the switch rolled back.
- **Runtime swap**: `AppDatabaseController.migrateEncryptionPreservingData` (`lib/core/providers/database_providers.dart`) holds the active `AppDatabase` so the app does not need a full restart after a successful toggle.
- **Manual backup**: `BackupService` + `BackupPayloadV1` (`lib/core/data/`) write UTF-8 JSON with `format: splitbae_backup`, `version: 1`. **Encrypted-at-rest `.sb_backup`** (e.g. age/minisign) is a future enhancement; today the UI warns that the export is readable by anyone with the file. **Settings → Manual backup** opens [`lib/screens/backup_screen.dart`](lib/screens/backup_screen.dart) (export + share, import + confirm); the list row lives in [`settings_screen.dart`](lib/screens/settings_screen.dart).
- **Snap & split (OCR)**: [`ReceiptOcrChannel`](lib/core/ocr/receipt_ocr_channel.dart) uses `MethodChannel('splitbae/receipt_ocr')`. **Android** ([`MainActivity.kt`](android/app/src/main/kotlin/com/example/splitbae/MainActivity.kt)): Google ML Kit Text Recognition Latin. **iOS** ([`SceneDelegate.swift`](ios/Runner/SceneDelegate.swift)): Apple **Vision** `VNRecognizeTextRequest` (read order sorted by `boundingBox`; revision 3 on iOS 16+). Native **`probe`** returns engine readiness without an image; [`receiptOcrProbeProvider`](lib/core/ocr/receipt_ocr_probe_provider.dart) is warmed from [`AdaptiveHomeScreen`](lib/screens/adaptive_home_screen.dart). If the probe fails or OCR times out, the UI **never** blocks manual entry—add-item sheet always has **Enter manually** in the scan sheet and typed fields. [`runReceiptScanFlow`](lib/widgets/receipt_scan_flow.dart) + [`image_picker`](https://pub.dev/packages/image_picker) hook into **Add item** ([`add_receipt_item_sheet.dart`](lib/widgets/add_receipt_item_sheet.dart)); [`parseReceiptLineCandidates`](lib/core/ocr/receipt_line_parse.dart) runs [`refineOcrText`](lib/core/ocr/receipt_ocr_refiner.dart) then heuristics (user can edit before save). Web/desktop: scan is disabled (`isSupported` is Android/iOS only).
- **Who owes what**: [`ReceiptLineAssignments`](lib/core/database/app_database.dart) (many-to-many line ↔ participant). Empty assignment rows for a line means **everyone** splits that line equally. [`calculate_split_assigned`](rust/src/api/simple.rs) sums each person’s share per currency; [`ItemAssigneeChips`](lib/widgets/item_assignee_chips.dart) on the home list and add/edit sheet toggles assignees.

## Platform UI (Flutter)

- **Material You (Android 12+)**: `dynamic_color` feeds the OS accent into `ThemeData.colorScheme` when available; otherwise the app falls back to a seed palette.
- **Edge-to-edge**: `configureSplitBaePlatform()` (`lib/core/platform/platform_bootstrap.dart`) enables `SystemUiMode.edgeToEdge` and transparent system bars on mobile—`Scaffold` / `SafeArea` handle insets.
- **Adaptive chrome**: Use `splitBaeAdaptiveAppBar` / `splitBaeAdaptiveToolbarIcon` (`lib/core/widgets/adaptive_app_bar.dart`) for top bars and toolbar actions so **iOS** gets `CupertinoNavigationBar` + `CupertinoButton` instead of only Material `AppBar` / `IconButton`.
- **Apple narrow shell**: When `hostPlatformIsApple()` (`lib/core/platform/host_platform.dart` — `Platform.isIOS || Platform.isMacOS` with a web-safe stub), the narrow home layout uses **`CupertinoPageScaffold`** + **`CupertinoNavigationBar`** and a **`CupertinoButton.filled`** primary action instead of `Scaffold` + `FloatingActionButton`. Tablet/desktop rail layouts stay **`Scaffold`** + **NavigationRail** (Material sidebar).
- **Theming & a11y**: `splitBaeMaterialTheme` + `splitBaeAppBuilder` (`lib/core/theme/splitbae_theme.dart`) apply **Material 3** with **Roboto vs SF-like** typography via `Typography.material2021(platform: …)`, **`VisualDensity.adaptivePlatformDensity`**, padded tap targets, and on Apple a **`CupertinoTheme`** bridge so Cupertino controls track the same `ColorScheme`. **System text size, bold text, reduce motion,** and other **`MediaQuery` accessibility flags** come from the engine and are not overridden. Horizontal gutters use **`splitBaePageHorizontalPadding`** (`lib/core/layout/adaptive_insets.dart`) so content breathes slightly as text scale increases.
- **Adaptive dialogs**: Use `showAdaptiveConfirmDialog` for yes/no flows so iOS gets a Cupertino-style presentation; keep plain `AlertDialog` when the content is a `TextField` or other non-adaptive body.
- **Desktop**: `⌘,` / `Ctrl+,` opens Settings (`AdaptiveHomeScreen`); tooltips on the settings action hint the shortcut.
- **Android predictive back**: `android:enableOnBackInvokedCallback="true"` on the main activity (API 33+).

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
