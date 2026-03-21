import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/core/platform/adaptive_confirm_dialog.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/core/layout/adaptive_insets.dart';
import 'package:splitbae/providers.dart';

/// Manual backup: write `.sb_backup` JSON and share, or pick a file to restore.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final h = splitBaePageHorizontalPadding(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: splitBaeAdaptiveAppBar(
        context: context,
        title: l10n.settingsBackup,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(h, 16, h, 32),
        children: [
          Text(
            l10n.settingsBackupExportSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(l10n.settingsBackupExport),
            onPressed: () => _exportBackup(context, ref),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.settingsBackupImportSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.download_outlined),
            label: Text(l10n.settingsBackupImport),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
            ),
            onPressed: () => _importBackup(context, ref),
          ),
        ],
      ),
    );
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.backupExportSuccess)));
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.backupErrorExport)));
    }
  } finally {
    _dismissBlockingProgress(context);
  }
}

Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showAdaptiveConfirmDialog(
    context: context,
    title: Text(l10n.backupImportConfirmTitle),
    content: Text(l10n.backupImportConfirmBody),
    cancelLabel: l10n.cancel,
    confirmLabel: l10n.backupImportConfirmAction,
    confirmIsDestructive: true,
  );
  if (confirmed != true || !context.mounted) return;

  _showBlockingProgress(context);
  try {
    final didImport = await ref
        .read(backupServiceProvider)
        .importFromUserPick();
    if (!didImport) {
      return;
    }
    await ref.read(itemsProvider.notifier).reloadFromDatabase();
    await ref.read(participantsProvider.notifier).reloadFromDatabase();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.backupImportSuccess)));
  } on FormatException catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.backupErrorInvalid)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.backupErrorInvalid)));
    }
  } finally {
    _dismissBlockingProgress(context);
  }
}
