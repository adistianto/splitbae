import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/data/ledger_repository.dart';
import 'package:splitbae/core/database/database_opener.dart';
import 'package:splitbae/core/platform/platform_bootstrap.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/src/rust/frb_generated.dart';
import 'package:splitbae/screens/adaptive_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureSplitBaePlatform();
  await RustLib.init();
  final db = await openAppDatabase();
  await LedgerRepository(db).ensureSeedData();
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => AppDatabaseController(db)),
      ],
      child: const SplitBaeApp(),
    ),
  );
}

class SplitBaeApp extends ConsumerWidget {
  const SplitBaeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appSettingsProvider);
    final settings = ref.watch(appSettingsProvider);

    return DynamicColorBuilder(
      builder: (_, darkDynamic) {
        final colorScheme =
            darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            );
        return MaterialApp(
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
          locale: settings.materialLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          scrollBehavior: const SplitBaeScrollBehavior(),
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            brightness: Brightness.dark,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const AdaptiveHomeScreen(),
        );
      },
    );
  }
}
