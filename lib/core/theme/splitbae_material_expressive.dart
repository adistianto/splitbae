import 'package:flutter/material.dart';

/// Material 3 **Expressive** overlay for **Android** (and non-Apple targets):
/// stronger shapes, tonal navigation affordances, consistent sheet/dialog radii.
///
/// Apple hosts use [splitBaeMaterialTheme] without this merge so Liquid Glass
/// shell tokens stay the differentiator on frosted chrome only.
ThemeData mergeMaterialExpressive(ThemeData base) {
  final cs = base.colorScheme;
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  );
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        shape: WidgetStatePropertyAll(shape),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      dragHandleColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
    ),
  );
}
