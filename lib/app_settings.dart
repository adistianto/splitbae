import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/prefs_keys.dart';

export 'core/prefs_keys.dart' show kEncryptDatabasePreferenceKey;

const _kFollowSystem = 'follow_system_locale';
const _kAppLocaleCode = 'app_locale_code';
const _kDefaultCurrency = 'default_currency';
const _kThemeMode = 'theme_mode';
const _kUseDynamicColor = 'use_dynamic_color';

class AppSettings {
  const AppSettings({
    required this.followSystemLocale,
    required this.appLocaleCode,
    required this.defaultCurrencyCode,
    required this.encryptDatabase,
    required this.themeModeCode,
    required this.useDynamicColor,
  });

  /// When true, [MaterialApp.locale] stays null so Flutter follows the device.
  final bool followSystemLocale;

  /// Used when [followSystemLocale] is false (`en` or `id`).
  final String appLocaleCode;

  /// Default ISO 4217 code for new receipt lines.
  final String defaultCurrencyCode;

  /// When true, local SQLite should use encryption (SQLCipher) once implemented.
  /// Default off; user is nudged to enable in Settings.
  final bool encryptDatabase;

  /// `system` | `light` | `dark` — persisted for [MaterialApp.themeMode].
  final String themeModeCode;

  /// Wallpaper-driven palette when **device supports** Material You; otherwise ignored.
  final bool useDynamicColor;

  Locale? get materialLocale =>
      followSystemLocale ? null : Locale(appLocaleCode);

  ThemeMode get themeMode {
    switch (themeModeCode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppSettings copyWith({
    bool? followSystemLocale,
    String? appLocaleCode,
    String? defaultCurrencyCode,
    bool? encryptDatabase,
    String? themeModeCode,
    bool? useDynamicColor,
  }) {
    return AppSettings(
      followSystemLocale: followSystemLocale ?? this.followSystemLocale,
      appLocaleCode: appLocaleCode ?? this.appLocaleCode,
      defaultCurrencyCode: defaultCurrencyCode ?? this.defaultCurrencyCode,
      encryptDatabase: encryptDatabase ?? this.encryptDatabase,
      themeModeCode: themeModeCode ?? this.themeModeCode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    );
  }

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final rawTheme = p.getString(_kThemeMode) ?? 'system';
    const validThemes = {'system', 'light', 'dark'};
    final theme = validThemes.contains(rawTheme) ? rawTheme : 'system';
    return AppSettings(
      followSystemLocale: p.getBool(_kFollowSystem) ?? true,
      appLocaleCode: p.getString(_kAppLocaleCode) ?? 'en',
      defaultCurrencyCode: p.getString(_kDefaultCurrency) ?? 'IDR',
      encryptDatabase: p.getBool(kEncryptDatabasePreferenceKey) ?? false,
      themeModeCode: theme,
      useDynamicColor: p.getBool(_kUseDynamicColor) ??
          (defaultTargetPlatform == TargetPlatform.android),
    );
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFollowSystem, followSystemLocale);
    await p.setString(_kAppLocaleCode, appLocaleCode);
    await p.setString(_kDefaultCurrency, defaultCurrencyCode);
    await p.setBool(kEncryptDatabasePreferenceKey, encryptDatabase);
    await p.setString(_kThemeMode, themeModeCode);
    await p.setBool(_kUseDynamicColor, useDynamicColor);
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier()
    : super(
        AppSettings(
          followSystemLocale: true,
          appLocaleCode: 'en',
          defaultCurrencyCode: 'IDR',
          encryptDatabase: false,
          themeModeCode: 'system',
          useDynamicColor: defaultTargetPlatform == TargetPlatform.android,
        ),
      ) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    state = await AppSettings.load();
  }

  Future<void> setFollowDeviceLanguage() async {
    final next = state.copyWith(followSystemLocale: true);
    state = next;
    await next.persist();
  }

  Future<void> setExplicitLanguage(String languageCode) async {
    final next = state.copyWith(
      followSystemLocale: false,
      appLocaleCode: languageCode,
    );
    state = next;
    await next.persist();
  }

  Future<void> setDefaultCurrency(String code) async {
    final next = state.copyWith(defaultCurrencyCode: code);
    state = next;
    await next.persist();
  }

  Future<void> setEncryptDatabase(bool enabled) async {
    final next = state.copyWith(encryptDatabase: enabled);
    state = next;
    await next.persist();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final code = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    final next = state.copyWith(themeModeCode: code);
    state = next;
    await next.persist();
  }

  Future<void> setUseDynamicColor(bool enabled) async {
    final next = state.copyWith(useDynamicColor: enabled);
    state = next;
    await next.persist();
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      return AppSettingsNotifier();
    });

final defaultCurrencyProvider = Provider<String>((ref) {
  return ref.watch(appSettingsProvider).defaultCurrencyCode;
});

final encryptDatabaseProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).encryptDatabase;
});
