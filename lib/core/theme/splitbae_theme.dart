import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splitbae/core/platform/host_platform.dart';

/// Material 3 theme tuned for the host platform’s typography (Roboto vs SF-like).
ThemeData splitBaeMaterialTheme({required ColorScheme colorScheme}) {
  final apple = hostPlatformIsApple();
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: colorScheme.brightness,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    ),
    typography: Typography.material2021(
      platform: apple ? TargetPlatform.iOS : TargetPlatform.android,
    ),
  );
}

/// Root [MaterialApp.builder]: bridges [CupertinoTheme] on Apple platforms so
/// Cupertino widgets inherit SF metrics; system accessibility (text scale, bold
/// text, reduce motion, contrast flags) flows from the engine via [MediaQuery].
Widget splitBaeAppBuilder(BuildContext context, Widget? child) {
  if (child == null) return const SizedBox.shrink();

  final theme = Theme.of(context);
  Widget tree = child;

  if (hostPlatformIsApple()) {
    final cs = theme.colorScheme;
    tree = CupertinoTheme(
      data: CupertinoThemeData(
        brightness: theme.brightness,
        primaryColor: cs.primary,
        primaryContrastingColor: cs.onPrimary,
        scaffoldBackgroundColor: cs.surface,
        barBackgroundColor: cs.surface,
        applyThemeToAll: true,
        textTheme: CupertinoTextThemeData(
          primaryColor: cs.onSurface,
          textStyle: theme.textTheme.bodyLarge,
          actionTextStyle: theme.textTheme.labelLarge,
          tabLabelTextStyle: theme.textTheme.labelMedium,
          navTitleTextStyle: theme.textTheme.titleLarge,
          navLargeTitleTextStyle: theme.textTheme.headlineSmall,
          pickerTextStyle: theme.textTheme.titleMedium,
          dateTimePickerTextStyle: theme.textTheme.titleMedium,
        ),
      ),
      child: tree,
    );
  }

  return tree;
}
