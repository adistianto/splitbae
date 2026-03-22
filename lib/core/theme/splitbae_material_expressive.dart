import 'package:flutter/material.dart';
import 'package:tofu_expressive/tofu_expressive.dart';

/// Layers **Tofu Expressive** (`flex_color_scheme`) dialog / sheet affordances onto
/// the SplitBae base theme. Does **not** use plain `CardTheme` / `NavigationRailTheme`
/// — navigation and surfaces come from **m3e_collection** widgets + [M3ETheme] tokens
/// ([withM3ETheme] in [splitBaeMaterialTheme]).
///
/// Apple hosts skip this merge ([splitBaeMaterialTheme] gates the call).
ThemeData mergeMaterialExpressive(ThemeData base) {
  final cs = base.colorScheme;
  final tofu = cs.brightness == Brightness.dark
      ? TofuTheme.dark(seedColor: cs.primary)
      : TofuTheme.light(seedColor: cs.primary);
  return base.copyWith(
    dialogTheme: tofu.dialogTheme,
    bottomSheetTheme: tofu.bottomSheetTheme,
  );
}
