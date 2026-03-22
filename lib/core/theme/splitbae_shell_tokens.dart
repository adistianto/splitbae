import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// **Shell chrome tokens** — how we split **Android Material 3 Expressive** vs
/// **Apple Liquid Glass** without two apps.
///
/// ## v0 reference
/// Workflows and IA follow `vercel/SplitBae_v76_Vercel.v0/` (Bills · Balances,
/// FAB, scan, sheets). Visuals use native primitives: M3 on Android, frosted
/// translucency on Apple for **shell** surfaces only (bars, floating controls).
///
/// ## Android
/// [liquidGlassChrome] is false; prefer elevation and solid/tonal surfaces.
/// [searchFieldMaterialElevation] is non-zero for the floating search field.
///
/// ## Apple (iPhone, iPad, macOS)
/// [liquidGlassChrome] is true; [chromeBlurSigma] / [bottomBarBlurSigma] drive
/// [BackdropFilter] in shell widgets. Content areas stay normal [Scaffold] /
/// [CupertinoTheme] text — glass is for **chrome**, not every card.
///
/// Registered in [splitBaeMaterialTheme] next to [SplitBaeSemanticColors].
@immutable
class SplitBaeShellTokens extends ThemeExtension<SplitBaeShellTokens> {
  const SplitBaeShellTokens({
    required this.liquidGlassChrome,
    required this.chromeBlurSigma,
    required this.chromeTintAlpha,
    required this.chromeBorderOpacity,
    required this.bottomBarBlurSigma,
    required this.bottomBarTintAlpha,
    required this.searchFieldMaterialElevation,
  });

  /// When true (Apple hosts), shell widgets use frosted glass.
  final bool liquidGlassChrome;

  /// Floating header icon buttons and similar chrome.
  final double chromeBlurSigma;
  final double chromeTintAlpha;
  final double chromeBorderOpacity;

  /// Bottom navigation scrim (Apple).
  final double bottomBarBlurSigma;
  final double bottomBarTintAlpha;

  /// Android search field uses Material elevation; Apple uses 0 + glass.
  final double searchFieldMaterialElevation;

  static SplitBaeShellTokens android() {
    return const SplitBaeShellTokens(
      liquidGlassChrome: false,
      chromeBlurSigma: 0,
      chromeTintAlpha: 0.95,
      chromeBorderOpacity: 0,
      bottomBarBlurSigma: 0,
      bottomBarTintAlpha: 0.94,
      searchFieldMaterialElevation: 6,
    );
  }

  static SplitBaeShellTokens apple() {
    return const SplitBaeShellTokens(
      liquidGlassChrome: true,
      chromeBlurSigma: 12,
      chromeTintAlpha: 0.72,
      chromeBorderOpacity: 0.35,
      bottomBarBlurSigma: 20,
      bottomBarTintAlpha: 0.78,
      searchFieldMaterialElevation: 0,
    );
  }

  @override
  SplitBaeShellTokens copyWith({
    bool? liquidGlassChrome,
    double? chromeBlurSigma,
    double? chromeTintAlpha,
    double? chromeBorderOpacity,
    double? bottomBarBlurSigma,
    double? bottomBarTintAlpha,
    double? searchFieldMaterialElevation,
  }) {
    return SplitBaeShellTokens(
      liquidGlassChrome: liquidGlassChrome ?? this.liquidGlassChrome,
      chromeBlurSigma: chromeBlurSigma ?? this.chromeBlurSigma,
      chromeTintAlpha: chromeTintAlpha ?? this.chromeTintAlpha,
      chromeBorderOpacity: chromeBorderOpacity ?? this.chromeBorderOpacity,
      bottomBarBlurSigma: bottomBarBlurSigma ?? this.bottomBarBlurSigma,
      bottomBarTintAlpha: bottomBarTintAlpha ?? this.bottomBarTintAlpha,
      searchFieldMaterialElevation:
          searchFieldMaterialElevation ?? this.searchFieldMaterialElevation,
    );
  }

  @override
  SplitBaeShellTokens lerp(
    ThemeExtension<SplitBaeShellTokens>? other,
    double t,
  ) {
    if (other is! SplitBaeShellTokens) return this;
    return SplitBaeShellTokens(
      liquidGlassChrome: t < 0.5 ? liquidGlassChrome : other.liquidGlassChrome,
      chromeBlurSigma: lerpDouble(chromeBlurSigma, other.chromeBlurSigma, t)!,
      chromeTintAlpha: lerpDouble(chromeTintAlpha, other.chromeTintAlpha, t)!,
      chromeBorderOpacity:
          lerpDouble(chromeBorderOpacity, other.chromeBorderOpacity, t)!,
      bottomBarBlurSigma:
          lerpDouble(bottomBarBlurSigma, other.bottomBarBlurSigma, t)!,
      bottomBarTintAlpha:
          lerpDouble(bottomBarTintAlpha, other.bottomBarTintAlpha, t)!,
      searchFieldMaterialElevation: lerpDouble(
        searchFieldMaterialElevation,
        other.searchFieldMaterialElevation,
        t,
      )!,
    );
  }
}
