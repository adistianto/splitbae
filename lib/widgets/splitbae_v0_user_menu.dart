import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/backup_screen.dart';
import 'package:splitbae/screens/settings_screen.dart';

/// v0 [user-menu]: slide-in panel with journey stats and shortcuts to full settings.
Future<void> showSplitBaeV0UserMenu(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: Material(
              elevation: 12,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(32),
              ),
              clipBehavior: Clip.antiAlias,
              child: _V0UserMenuBody(
                onClose: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}

class _V0UserMenuBody extends ConsumerWidget {
  const _V0UserMenuBody({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final width = (MediaQuery.sizeOf(context).width * 0.92).clamp(300.0, 360.0);
    final posted = ref.watch(postedBillSummariesProvider);
    final people = ref.watch(participantsProvider);

    final maxH = MediaQuery.sizeOf(context).height * 0.88;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: maxH),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.v0UserMenuTitle,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.v0UserMenuSubtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: posted.when(
                data: (summaries) {
                  final billCount = summaries.length;
                  final friendCount = people.length;
                  int? firstMs;
                  for (final s in summaries) {
                    final t = s.transaction.createdAtMs;
                    if (firstMs == null || t < firstMs) firstMs = t;
                  }
                  final memberLabel = firstMs != null
                      ? l10n.v0UserMenuMemberSince(
                          DateFormat.yMMMM(
                            locale.toString(),
                          ).format(
                            DateTime.fromMillisecondsSinceEpoch(firstMs),
                          ),
                        )
                      : l10n.v0UserMenuMemberSinceNew;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              cs.primary,
                              Color.lerp(cs.primary, cs.tertiary, 0.2)!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: cs.onPrimary.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.v0UserMenuJourney,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: cs.onPrimary
                                            .withValues(alpha: 0.9),
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              memberLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onPrimary.withValues(alpha: 0.88),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCell(
                                    value: '$billCount',
                                    label: l10n.v0UserMenuStatBills,
                                    onPrimary: cs.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _StatCell(
                                    value: '$friendCount',
                                    label: l10n.v0UserMenuStatFriends,
                                    onPrimary: cs.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onClose();
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined),
                        label: Text(l10n.v0UserMenuOpenFullSettings),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onClose();
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const BackupScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(l10n.settingsBackup),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('$e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.onPrimary,
  });

  final String value;
  final String label;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: onPrimary.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}
