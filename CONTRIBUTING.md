# Contributing to SplitBae

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
| Rust ↔ Dart bridge | From repo root: `flutter_rust_bridge_codegen generate` |
| Rust check | `cd rust && cargo check` |
| Analyze | `dart analyze` / `flutter analyze` |

After changing **`rust/src/api/`** or FRB types, regenerate the bridge **before** opening a PR.

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
