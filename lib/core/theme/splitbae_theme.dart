import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/theme/splitbae_material_expressive.dart';
import 'package:splitbae/core/theme/splitbae_semantic_colors.dart';
import 'package:splitbae/core/theme/splitbae_shell_tokens.dart';

/// Material 3 theme tuned for the host platform’s typography (Roboto vs SF-like).
///
/// [colorScheme] is usually from **dynamic color** (Android wallpaper) or the
/// v0 seed palette. **Error** roles use fixed destructive tones from
/// [SplitBaeSemanticColors]; insight and category accents are **harmonized**
/// toward the live scheme for a cohesive Material You look without recoloring
/// pay/receive semantics.
///
/// **Android**: [mergeMaterialExpressive] adds M3 expressive shapes + sheets.
/// **Apple**: [SplitBaeShellTokens.apple] enables Liquid Glass shell chrome
/// (see [splitBaeAppBuilder] + frosted shell widgets).
ThemeData splitBaeMaterialTheme({required ColorScheme colorScheme}) {
  final apple = hostPlatformIsApple();
  final semanticBase = colorScheme.brightness == Brightness.dark
      ? SplitBaeSemanticColors.dark
      : SplitBaeSemanticColors.light;

  final cs = colorScheme.copyWith(
    error: semanticBase.destructive,
    onError: semanticBase.onDestructive,
    errorContainer: semanticBase.destructiveContainer,
    onErrorContainer: semanticBase.onDestructiveContainer,
  );

  final semantic = SplitBaeSemanticColors.harmonizedWithScheme(
    base: semanticBase,
    scheme: cs,
  );

  final shellTokens =
      apple ? SplitBaeShellTokens.apple() : SplitBaeShellTokens.android();

  final typo = Typography.material2021(
    platform: apple ? TargetPlatform.iOS : TargetPlatform.android,
  );
  final navLabelStyle = (cs.brightness == Brightness.dark ? typo.white : typo.black)
      .labelMedium
      ?.copyWith(fontWeight: FontWeight.w600);

  var theme = ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    brightness: cs.brightness,
    extensions: <ThemeExtension<dynamic>>[semantic, shellTokens],
    visualDensity: VisualDensity.adaptivePlatformDensity,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: cs.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.all(navLabelStyle),
    ),
    typography: Typography.material2021(
      platform: apple ? TargetPlatform.iOS : TargetPlatform.android,
    ),
  );

  if (!apple) {
    theme = mergeMaterialExpressive(theme);
  }
  return theme;
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
