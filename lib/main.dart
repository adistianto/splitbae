import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/settings_screen.dart';
import 'package:splitbae/src/rust/frb_generated.dart';
import 'package:splitbae/widgets/add_receipt_item_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const ProviderScope(child: SplitBaeApp()));
}

class SplitBaeApp extends ConsumerWidget {
  const SplitBaeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appSettingsProvider);
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      locale: settings.materialLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final splitAsync = ref.watch(splitProvider);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.addItemTooltip,
            onPressed: () => showAddReceiptItemSheet(context, ref),
            icon: const Icon(Icons.add_shopping_cart_outlined),
          ),
          IconButton(
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.splitSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: splitAsync.when(
              data: (results) => ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 88),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final res = results[index];
                  final formatted = formatCurrencyAmount(
                    amount: res.totalOwed,
                    currencyCode: res.currencyCode,
                    locale: locale,
                  );
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          res.personName[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        res.personName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(res.currencyCode),
                      trailing: Text(
                        formatted,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(participantsProvider.notifier).addParticipant('New Friend');
        },
        label: Text(l10n.addPerson),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}
