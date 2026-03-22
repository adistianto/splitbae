import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/theme/splitbae_shell_tokens.dart';

/// Whether the active theme requests **Liquid Glass Easy** shell chrome on Apple
/// (replaces legacy [BackdropFilter] frosted panels).
bool splitBaeAppleLiquidGlassChromeEnabled(BuildContext context) {
  final tokens = Theme.of(context).extension<SplitBaeShellTokens>() ??
      SplitBaeShellTokens.android();
  return hostPlatformIsApple() && tokens.liquidGlassChrome;
}

/// Height of the bottom tab strip lens (M3E medium bar ≈ 80dp + safe inset).
double splitBaeAppleBottomBarLensHeight(BuildContext context) {
  final bottom = MediaQuery.paddingOf(context).bottom;
  return 80.0 + bottom;
}

/// Default width for the navigation rail lens (matches [NavigationRailM3ETheme]).
double splitBaeAppleRailLensWidth(BuildContext context, {required bool expanded}) {
  final t = Theme.of(context).extension<NavigationRailM3ETheme>() ??
      const NavigationRailM3ETheme();
  return expanded ? t.expandedMinWidth : t.collapsedWidth;
}

/// Full-viewport host: **only** the listed lenses run the glass shader; the
/// [background] subtree (scroll views, lists) is drawn normally and sampled for
/// refraction — not blurred by a shell-wide [BackdropFilter].
///
/// Uses throttled background capture ([LiquidGlassRefreshRate.medium]) and a
/// capped [pixelRatio] so scrolling stays responsive vs. capturing every frame
/// at full resolution.
Widget splitBaeAppleLiquidGlassViewport({
  required Widget background,
  required List<LiquidGlass> lenses,
  LiquidGlassViewController? controller,
}) {
  return LiquidGlassView(
    controller: controller,
    backgroundWidget: background,
    children: lenses,
    pixelRatio: 0.72,
    realTimeCapture: true,
    refreshRate: LiquidGlassRefreshRate.medium,
    useSync: true,
  );
}

/// Bottom tab bar strip: refractive glass with chromatic separation and strong
/// edge speculars (visionOS / iOS 26–style physical slab).
LiquidGlass splitBaeAppleBottomTabBarLens({
  required double width,
  required double height,
  required Widget child,
}) {
  return LiquidGlass(
    width: width,
    height: height,
    position: const LiquidGlassOffsetPosition(left: 0, right: 0, bottom: 0),
    magnification: 1.03,
    refractionMode: LiquidGlassRefractionMode.shapeRefraction,
    distortion: 0.14,
    distortionWidth: 34,
    chromaticAberration: 0.006,
    saturation: 1.05,
    blur: const LiquidGlassBlur(sigmaX: 0.38, sigmaY: 0.38),
    color: const Color(0x14FFFFFF),
    shape: RoundedRectangleShape(
      cornerRadius: 26,
      borderWidth: 1.4,
      borderSoftness: 2.4,
      lightIntensity: 1.5,
      oneSideLightIntensity: 1.2,
      lightDirection: 42,
      lightMode: LiquidGlassLightMode.edge,
      lightColor: const Color(0xD9FFFFFF),
      shadowColor: const Color(0x33000000),
    ),
    draggable: false,
    outOfBoundaries: false,
    child: child,
  );
}

/// Side rail: superellipse lens with a slightly different light rake so rail +
/// tab bar don’t look identical.
LiquidGlass splitBaeAppleNavigationRailLens({
  required double width,
  required double height,
  required Widget child,
}) {
  return LiquidGlass(
    width: width,
    height: height,
    position: const LiquidGlassOffsetPosition(left: 0, top: 0),
    magnification: 1.025,
    refractionMode: LiquidGlassRefractionMode.shapeRefraction,
    distortion: 0.12,
    distortionWidth: 30,
    chromaticAberration: 0.005,
    saturation: 1.04,
    blur: const LiquidGlassBlur(sigmaX: 0.32, sigmaY: 0.32),
    color: const Color(0x12FFFFFF),
    shape: SuperellipseShape(
      curveExponent: 3.6,
      borderWidth: 1.2,
      borderSoftness: 2.0,
      lightIntensity: 1.42,
      oneSideLightIntensity: 1.05,
      lightDirection: 28,
      lightMode: LiquidGlassLightMode.edge,
      lightColor: const Color(0xCCFFFFFF),
      shadowColor: const Color(0x28000000),
    ),
    draggable: false,
    outOfBoundaries: false,
    child: child,
  );
}
