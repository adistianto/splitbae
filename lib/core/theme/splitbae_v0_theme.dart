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

/// Dark palette aligned with v0 `globals.css` `.dark` (teal primary on deep slate).
ColorScheme splitBaeV0DarkColorScheme() {
  final base = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2DD4BF),
    brightness: Brightness.dark,
  );
  return base.copyWith(
    surface: const Color(0xFF0F172A),
    onSurface: const Color(0xFFF1F5F9),
    surfaceContainerLowest: const Color(0xFF020617),
    surfaceContainerHighest: const Color(0xFF1E293B),
    onSurfaceVariant: const Color(0xFF94A3B8),
    outline: const Color(0xFF334155),
    outlineVariant: const Color(0xFF1E293B),
    primaryContainer: const Color(0xFF134E4A),
    onPrimaryContainer: const Color(0xFFCCFBF1),
    secondaryContainer: const Color(0xFF4C1D95),
    onSecondaryContainer: const Color(0xFFE9D5FF),
    tertiary: const Color(0xFFFB923C),
    onTertiary: const Color(0xFF431407),
    error: const Color(0xFFF87171),
    onError: const Color(0xFF450A0A),
  );
}
