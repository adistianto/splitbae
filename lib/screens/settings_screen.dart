import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/core/platform/adaptive_confirm_dialog.dart';
import 'package:splitbae/screens/backup_screen.dart';
import 'package:splitbae/currency_catalog.dart';
import 'package:splitbae/providers.dart';

enum _LanguageChoice { device, english, indonesian }

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}

_LanguageChoice _languageChoice(AppSettings s) {
  if (s.followSystemLocale) return _LanguageChoice.device;
  if (s.appLocaleCode == 'id') return _LanguageChoice.indonesian;
  return _LanguageChoice.english;
}

Future<void> _onEncryptDatabaseToggle({
  required BuildContext context,
  required WidgetRef ref,
  required bool requested,
}) async {
  final current = ref.read(appSettingsProvider).encryptDatabase;
  if (requested == current) return;

  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showAdaptiveConfirmDialog(
    context: context,
    title: Text(l10n.settingsEncryptChangeTitle),
    content: Text(l10n.settingsEncryptChangeBody),
    cancelLabel: l10n.cancel,
    confirmLabel: l10n.settingsEncryptChangeConfirm,
  );
  if (confirmed != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  try {
    final ok = await ref
        .read(appDatabaseProvider.notifier)
        .migrateEncryptionPreservingData(
          persistNewEncryptionPreference: () => ref
              .read(appSettingsProvider.notifier)
              .setEncryptDatabase(requested),
          setEncryptionPreference: (encrypt) => ref
              .read(appSettingsProvider.notifier)
              .setEncryptDatabase(encrypt),
          previousEncryption: current,
        );
    await ref.read(itemsProvider.notifier).reloadFromDatabase();
    await ref.read(participantsProvider.notifier).reloadFromDatabase();
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsEncryptMigrationRolledBack)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsEncryptChangeError)));
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

void _showBlockingProgress(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

void _dismissBlockingProgress(BuildContext context) {
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  _showBlockingProgress(context);
  try {
    final svc = ref.read(backupServiceProvider);
    final file = await svc.writeExportFile();
    await svc.shareExportFile(file);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.backupExportSuccess)),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupErrorExport)),
      );
    }
  } finally {
    _dismissBlockingProgress(context);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.embedded = false});

  /// When true (e.g. [NavigationRail] on large screens), no [AppBar]—the shell
  /// provides navigation.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final selected = _languageChoice(settings);

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = (constraints.maxWidth - 32).clamp(240.0, 560.0);
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.settingsLanguage,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.settingsLanguageSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _LanguageTile(
              label: l10n.languageDevice,
              selected: selected == _LanguageChoice.device,
              onTap: () => notifier.setFollowDeviceLanguage(),
            ),
            _LanguageTile(
              label: l10n.languageEnglish,
              selected: selected == _LanguageChoice.english,
              onTap: () => notifier.setExplicitLanguage('en'),
            ),
            _LanguageTile(
              label: l10n.languageIndonesian,
              selected: selected == _LanguageChoice.indonesian,
              onTap: () => notifier.setExplicitLanguage('id'),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.settingsDefaultCurrency,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.settingsDefaultCurrencySubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownMenu<String>(
                key: ValueKey(settings.defaultCurrencyCode),
                width: menuWidth,
                initialSelection: settings.defaultCurrencyCode,
                label: Text(l10n.currencyLabel),
                dropdownMenuEntries: [
                  for (final code in kSupportedCurrencyCodes)
                    DropdownMenuEntry(
                      value: code,
                      label: currencyMenuLabel(code),
                    ),
                ],
                onSelected: (code) {
                  if (code != null) notifier.setDefaultCurrency(code);
                },
              ),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.settingsDataPrivacy,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SwitchListTile.adaptive(
              value: settings.encryptDatabase,
              onChanged: (enabled) => _onEncryptDatabaseToggle(
                context: context,
                ref: ref,
                requested: enabled,
              ),
              title: Text(l10n.settingsEncryptDatabase),
              subtitle: Text(
                l10n.settingsEncryptDatabaseSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.settingsBackup,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FilledButton.icon(
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(l10n.settingsBackupExport),
                onPressed: () => _exportBackup(context, ref),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(l10n.settingsBackupManualTitle),
              subtitle: Text(
                l10n.settingsBackupEntrySubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
                );
              },
            ),
          ],
        );
      },
    );

    if (embedded) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: body,
    );
  }
}
