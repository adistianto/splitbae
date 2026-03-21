import 'dart:async' show unawaited;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/data/ledger_repository.dart';
import 'package:splitbae/core/database/database_opener.dart';
import 'package:splitbae/core/platform/platform_bootstrap.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/core/theme/dynamic_color_support.dart';
import 'package:splitbae/core/theme/splitbae_theme.dart';
import 'package:splitbae/core/theme/splitbae_v0_theme.dart';
import 'package:splitbae/src/rust/frb_generated.dart';
import 'package:splitbae/screens/adaptive_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureSplitBaePlatform();
  await RustLib.init();
  final dynamicColorSupported = await probeDynamicColorAvailable();
  final db = await openAppDatabase();
  await LedgerRepository(db).ensureSeedData();
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => AppDatabaseController(db)),
        dynamicColorSupportedProvider.overrideWith(
          (ref) => dynamicColorSupported,
        ),
      ],
      child: const SplitBaeApp(),
    ),
  );
}

class SplitBaeApp extends ConsumerStatefulWidget {
  const SplitBaeApp({super.key});

  @override
  ConsumerState<SplitBaeApp> createState() => _SplitBaeAppState();
}

class _SplitBaeAppState extends ConsumerState<SplitBaeApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDynamicColorPreference();
    });
  }

  /// Keeps SharedPreferences aligned when the device has no CorePalette (e.g. backup restore).
  void _syncDynamicColorPreference() {
    final supported = ref.read(dynamicColorSupportedProvider);
    final settings = ref.read(appSettingsProvider);
    if (!supported && settings.useDynamicColor) {
      unawaited(
        ref.read(appSettingsProvider.notifier).setUseDynamicColor(false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final supported = ref.watch(dynamicColorSupportedProvider);

    final useMaterialYou = defaultTargetPlatform == TargetPlatform.android &&
        settings.useDynamicColor &&
        supported;

    if (useMaterialYou) {
      return DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return _SplitBaeThemedApp(
            settings: settings,
            lightScheme: lightDynamic ?? splitBaeV0LightColorScheme(),
            darkScheme: darkDynamic ?? splitBaeV0DarkColorScheme(),
          );
        },
      );
    }

    return _SplitBaeThemedApp(
      settings: settings,
      lightScheme: splitBaeV0LightColorScheme(),
      darkScheme: splitBaeV0DarkColorScheme(),
    );
  }
}

class _SplitBaeThemedApp extends StatelessWidget {
  const _SplitBaeThemedApp({
    required this.settings,
    required this.lightScheme,
    required this.darkScheme,
  });

  final AppSettings settings;
  final ColorScheme lightScheme;
  final ColorScheme darkScheme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      locale: settings.materialLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      scrollBehavior: const SplitBaeScrollBehavior(),
      themeMode: settings.themeMode,
      theme: splitBaeMaterialTheme(colorScheme: lightScheme),
      darkTheme: splitBaeMaterialTheme(colorScheme: darkScheme),
      builder: splitBaeAppBuilder,
      home: const AdaptiveHomeScreen(),
    );
  }
}
