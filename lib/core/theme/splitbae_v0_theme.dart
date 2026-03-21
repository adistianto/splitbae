import 'package:flutter/material.dart';

/// Light palette aligned with [vercel/SplitBae_v76_Vercel.v0/app/globals.css] `:root`.
ColorScheme splitBaeV0LightColorScheme() {
  final base = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0D9488),
    brightness: Brightness.light,
  );
  return base.copyWith(
    surface: const Color(0xFFF8FAFA),
    onSurface: const Color(0xFF0F172A),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerHighest: const Color(0xFFE2E8F0),
    onSurfaceVariant: const Color(0xFF64748B),
    outline: const Color(0xFFCBD5E1),
    outlineVariant: const Color(0xFFE2E8F0),
    primaryContainer: const Color(0xFFCCFBF1),
    onPrimaryContainer: const Color(0xFF134E4A),
    secondaryContainer: const Color(0xFFF3E8FF),
    onSecondaryContainer: const Color(0xFF5B21B6),
    tertiary: const Color(0xFFEA580C),
    onTertiary: Colors.white,
    error: const Color(0xFFDC2626),
    onError: Colors.white,
  );
}
