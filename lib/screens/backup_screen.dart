import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:splitbae/core/layout/adaptive_insets.dart';
import 'package:splitbae/core/ui/splitbae_motion.dart';
import 'package:splitbae/core/platform/adaptive_confirm_dialog.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/features/settings/application/backup_provider.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final h = splitBaePageHorizontalPadding(context);
    final cs = Theme.of(context).colorScheme;
    final m3e = context.m3e;

    final op = ref.watch(backupOperationProvider);
    final busy = op.isLoading;

    const exportSubtitle = 'Portable backup bundle (.splitbae) including the database and receipt images.';

    return Scaffold(
      appBar: splitBaeAdaptiveAppBar(
        context: context,
        title: l10n.settingsBackup,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(h, 16, h, 32),
        children: [
          Text(
            exportSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          if (busy) ...[
            Center(
              child: const CircularProgressIndicator(strokeWidth: 2)
                  .animate()
                  .fadeIn(
                    duration: splitBaeMountDuration(context),
                    curve: splitBaeMountCurve(context),
                  ),
            ),
            const SizedBox(height: 20),
          ],
          _ActionCard(
            icon: PhosphorIconsRegular.cloudArrowUp,
            title: 'Export Data',
            subtitle: exportSubtitle,
            color: m3e.colors.surfaceContainerLow,
            textColor: cs.onSurface,
            buttonColor: cs.primary,
            buttonTextColor: cs.onPrimary,
            disabled: busy,
            onTap: () async {
              await ref
                  .read(backupOperationProvider.notifier)
                  .exportData();

              final next = ref.read(backupOperationProvider);
              if (!context.mounted) return;
              if (next.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.backupErrorExport)),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.backupExportSuccess)),
              );
            },
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: PhosphorIconsRegular.downloadSimple,
            title: 'Import Backup',
            subtitle: l10n.settingsBackupImportSubtitle,
            color: m3e.colors.surfaceContainerLow,
            textColor: cs.onSurface,
            buttonColor: cs.error,
            buttonTextColor: cs.onError,
            disabled: busy,
            onTap: () async {
              final confirmed = await showAdaptiveConfirmDialog(
                context: context,
                title: Text(l10n.backupImportConfirmTitle),
                content: Text(l10n.backupImportConfirmBody),
                cancelLabel: l10n.cancel,
                confirmLabel: l10n.backupImportConfirmAction,
                confirmIsDestructive: true,
              );
              if (confirmed != true || !context.mounted) return;

              await ref
                  .read(backupOperationProvider.notifier)
                  .importBackup();

              final next = ref.read(backupOperationProvider);
              if (!context.mounted) return;
              if (next.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.backupErrorInvalid)),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.backupImportSuccess)),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.disabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color textColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final btn = FilledButton.icon(
      onPressed: disabled ? null : onTap,
      icon: Icon(icon, color: buttonTextColor),
      label: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: buttonTextColor,
            ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: buttonTextColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );

    return Material(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Icon(icon, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (disabled)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(width: 8),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            btn,
          ],
        ),
      ),
    );
  }
}
