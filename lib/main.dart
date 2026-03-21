import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/data/ledger_repository.dart';
import 'package:splitbae/core/database/database_opener.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/settings_screen.dart';
import 'package:splitbae/src/rust/frb_generated.dart';
import 'package:splitbae/widgets/add_receipt_item_sheet.dart';
import 'package:splitbae/widgets/manage_participants_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

Future<void> _confirmDeleteLine(
  BuildContext context,
  WidgetRef ref,
  LedgerLineItem line,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteItemTitle),
      content: Text(l10n.deleteItemBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.deleteAction),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await ref.read(itemsProvider.notifier).deleteItem(line.id);
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final splitAsync = ref.watch(splitProvider);
    final locale = Localizations.localeOf(context);
    final items = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.peopleTooltip,
            onPressed: () => showManageParticipantsSheet(context, ref),
            icon: const Icon(Icons.group_outlined),
          ),
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
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.billItemsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...items.map(
            (line) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  horizontal: 12,
                  vertical: 4,
                ),
                title: Text(
                  line.receiptItem.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(line.receiptItem.currencyCode),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatCurrencyAmount(
                        amount: line.receiptItem.price,
                        currencyCode: line.receiptItem.currencyCode,
                        locale: locale,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDeleteLine(context, ref, line),
                    ),
                  ],
                ),
                onTap: () => showAddReceiptItemSheet(
                  context,
                  ref,
                  existingLine: line,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              l10n.perPersonTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          splitAsync.when(
            data: (results) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final res in results)
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
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
                        formatCurrencyAmount(
                          amount: res.totalOwed,
                          currencyCode: res.currencyCode,
                          locale: locale,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: $err'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await ref
              .read(participantsProvider.notifier)
              .addParticipant('New Friend');
        },
        label: Text(l10n.addPerson),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}
