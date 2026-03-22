/// Visual and workflow alignment with the v0 concept
/// (`vercel/SplitBae_v76_Vercel.v0/`), implemented with **native** primitives:
/// Material 3 on Android, Cupertino-friendly surfaces and transitions on Apple
/// (see [splitBaeAppBuilder], [hostPlatformIsApple]).
///
/// **Workflow (unchanged from v0 IA)**  
/// Phone: **Bills** and **Balances** bottom tabs → floating search + profile →
/// FAB speed dial (Create Report → Balances, Scan Bill, New Bill) → scan as a
/// pushed full-screen flow → draft split / add-transaction sheets. Wide layouts
/// add a **Settings** rail destination; semantics stay the same.
///
/// Use these constants for spacing and radii so lists, hero cards, and FABs stay
/// consistent with the reference without copying web-only CSS pixel-for-pixel.
abstract final class SplitBaeV0Layout {
  SplitBaeV0Layout._();

  /// `page.tsx` / tab body horizontal padding (`px-5`).
  static const double screenHorizontalPadding = 20;

  /// Space below scroll content so the bottom bar + FAB do not obscure the last row.
  static const double listBottomInsetForShell = 120;

  /// Primary gradient card on Bills (`rounded-[28px]`).
  static const double heroBorderRadius = 28;

  /// Inset stats on the hero (`rounded-[14px]`).
  static const double heroStatBorderRadius = 14;

  /// Insight row pills (full stadium).
  static const double insightChipRadius = 999;

  /// Main FAB (`w-16 h-16`); closed shape uses [fabMainCornerRadiusClosed].
  static const double fabMainSize = 64;

  /// v0 closed FAB `rounded-[20px]`.
  static const double fabMainCornerRadiusClosed = 20;

  /// Open FAB → circle (`rounded-full` at same size).
  static const double fabMainCornerRadiusOpen = 28;

  /// Secondary FAB actions (`h-14` pill, `rounded-full`).
  static const double fabPillRadius = 28;

  /// `bottom-[calc(5rem+safe)]` → reserve above system nav + bottom bar.
  static const double fabBottomNavReserve = 80;

  /// Floating header icon buttons (`w-11 h-11`).
  static const double shellFloatingIconSize = 44;

  /// iOS/macOS frosted chrome — paired with [shellChromeBlurSigmaY].
  static const double shellChromeBlurSigma = 10;
}
