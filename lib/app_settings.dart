import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/prefs_keys.dart';

export 'core/prefs_keys.dart' show kEncryptDatabasePreferenceKey;

const _kFollowSystem = 'follow_system_locale';
const _kAppLocaleCode = 'app_locale_code';
const _kDefaultCurrency = 'default_currency';

class AppSettings {
  const AppSettings({
    required this.followSystemLocale,
    required this.appLocaleCode,
    required this.defaultCurrencyCode,
    required this.encryptDatabase,
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

  Locale? get materialLocale =>
      followSystemLocale ? null : Locale(appLocaleCode);

  AppSettings copyWith({
    bool? followSystemLocale,
    String? appLocaleCode,
    String? defaultCurrencyCode,
    bool? encryptDatabase,
  }) {
    return AppSettings(
      followSystemLocale: followSystemLocale ?? this.followSystemLocale,
      appLocaleCode: appLocaleCode ?? this.appLocaleCode,
      defaultCurrencyCode:
          defaultCurrencyCode ?? this.defaultCurrencyCode,
      encryptDatabase: encryptDatabase ?? this.encryptDatabase,
    );
  }

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      followSystemLocale: p.getBool(_kFollowSystem) ?? true,
      appLocaleCode: p.getString(_kAppLocaleCode) ?? 'en',
      defaultCurrencyCode: p.getString(_kDefaultCurrency) ?? 'IDR',
      encryptDatabase: p.getBool(kEncryptDatabasePreferenceKey) ?? false,
    );
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFollowSystem, followSystemLocale);
    await p.setString(_kAppLocaleCode, appLocaleCode);
    await p.setString(_kDefaultCurrency, defaultCurrencyCode);
    await p.setBool(kEncryptDatabasePreferenceKey, encryptDatabase);
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier()
      : super(
          const AppSettings(
            followSystemLocale: true,
            appLocaleCode: 'en',
            defaultCurrencyCode: 'IDR',
            encryptDatabase: false,
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
