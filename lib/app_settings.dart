import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFollowSystem = 'follow_system_locale';
const _kAppLocaleCode = 'app_locale_code';
const _kDefaultCurrency = 'default_currency';

class AppSettings {
  const AppSettings({
    required this.followSystemLocale,
    required this.appLocaleCode,
    required this.defaultCurrencyCode,
  });

  /// When true, [MaterialApp.locale] stays null so Flutter follows the device.
  final bool followSystemLocale;

  /// Used when [followSystemLocale] is false (`en` or `id`).
  final String appLocaleCode;

  /// Default ISO 4217 code for new receipt lines.
  final String defaultCurrencyCode;

  Locale? get materialLocale =>
      followSystemLocale ? null : Locale(appLocaleCode);

  AppSettings copyWith({
    bool? followSystemLocale,
    String? appLocaleCode,
    String? defaultCurrencyCode,
  }) {
    return AppSettings(
      followSystemLocale: followSystemLocale ?? this.followSystemLocale,
      appLocaleCode: appLocaleCode ?? this.appLocaleCode,
      defaultCurrencyCode:
          defaultCurrencyCode ?? this.defaultCurrencyCode,
    );
  }

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      followSystemLocale: p.getBool(_kFollowSystem) ?? true,
      appLocaleCode: p.getString(_kAppLocaleCode) ?? 'en',
      defaultCurrencyCode: p.getString(_kDefaultCurrency) ?? 'IDR',
    );
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFollowSystem, followSystemLocale);
    await p.setString(_kAppLocaleCode, appLocaleCode);
    await p.setString(_kDefaultCurrency, defaultCurrencyCode);
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier()
      : super(
          const AppSettings(
            followSystemLocale: true,
            appLocaleCode: 'en',
            defaultCurrencyCode: 'IDR',
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
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

final defaultCurrencyProvider = Provider<String>((ref) {
  return ref.watch(appSettingsProvider).defaultCurrencyCode;
});
