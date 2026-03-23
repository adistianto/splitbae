import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:splitbae/core/theme/splitbae_v0_ui_contract.dart';
import 'package:splitbae/l10n/app_localizations.dart';

/// v0-aligned **Bills** body — no data; M3 Expressive cards + hero rhythm.
class ShellBillsPlaceholder extends StatelessWidget {
  const ShellBillsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        SplitBaeV0Layout.screenHorizontalPadding,
        topPad + 24,
        SplitBaeV0Layout.screenHorizontalPadding,
        SplitBaeV0Layout.listBottomInsetForShell,
      ),
      children: [
        Text(
          l10n.appTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.appTagline,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ButtonM3E(
            style: ButtonM3EStyle.tonal,
            size: ButtonM3ESize.sm,
            onPressed: () {},
            icon: Icon(PhosphorIconsRegular.slidersHorizontal, size: 20),
            label: Text(l10n.billsFiltersTitle),
          ),
        ),
        const SizedBox(height: 12),
        const _ShellHeroCard(),
        const SizedBox(height: 12),
        _ShellInsightChipsRow(),
        const SizedBox(height: 20),
        Text(
          'MARCH ${DateTime.now().year}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _M3eSurfaceListTile(
          child: ListTile(
            title: Text(
              l10n.shellPlaceholderTransactionRow,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: Text(
              l10n.shellPlaceholderSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            trailing: Icon(
              PhosphorIconsRegular.caretRight,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _M3eSurfaceListTile extends StatelessWidget {
  const _M3eSurfaceListTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m3e = context.m3e;
    return Material(
      color: m3e.colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: m3e.shapes.square.lg),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: child,
    );
  }
}

class _ShellHeroCard extends StatelessWidget {
  const _ShellHeroCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SplitBaeV0Layout.heroBorderRadius),
        gradient: LinearGradient(
          colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.15)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.sparkle,
                    size: 16,
                    color: cs.onPrimary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.billsTotalExpenses.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.85),
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '—',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      label: l10n.billsThisWeek.toUpperCase(),
                      value: '—',
                      onPrimary: cs.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HeroStat(
                      label: l10n.billsAverage.toUpperCase(),
                      value: '—',
                      onPrimary: cs.onPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.onPrimary,
  });

  final String label;
  final String value;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          SplitBaeV0Layout.heroStatBorderRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: onPrimary.withValues(alpha: 0.75),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellInsightChipsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final m3e = context.m3e;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Pill(
            bg: m3e.colors.surfaceContainerHighest,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.receipt,
                  size: 16,
                  color: m3e.colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.shellPlaceholderChipBills,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Pill(
            bg: m3e.colors.secondaryContainer.withValues(alpha: 0.6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.chartLineUp,
                  size: 16,
                  color: m3e.colors.onSecondaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.shellPlaceholderChipTrend,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: m3e.colors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.bg, required this.child});

  final Color bg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m3e = context.m3e;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: m3e.shapes.square.sm),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: child,
      ),
    );
  }
}

/// v0-aligned **Balances** shell — list + settlement affordances (placeholder).
class ShellBalancesPlaceholder extends StatelessWidget {
  const ShellBalancesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        SplitBaeV0Layout.screenHorizontalPadding,
        topPad + 24,
        SplitBaeV0Layout.screenHorizontalPadding,
        SplitBaeV0Layout.listBottomInsetForShell,
      ),
      children: [
        Text(
          l10n.balancesTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.shellPlaceholderBalancesSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        _M3eSurfaceListTile(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(
                PhosphorIconsRegular.user,
                color: cs.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Text(l10n.shellPlaceholderPerson),
            subtitle: Text(l10n.shellPlaceholderBalance),
            trailing: ButtonM3E(
              style: ButtonM3EStyle.tonal,
              size: ButtonM3ESize.sm,
              onPressed: () {},
              label: Text(l10n.balancesTitle),
            ),
          ),
        ),
      ],
    );
  }
}

/// Settings column placeholder (wide rail third destination).
class ShellSettingsPlaceholder extends StatelessWidget {
  const ShellSettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.settings,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _M3eSurfaceListTile(
          child: ListTile(
            leading: Icon(PhosphorIconsRegular.gear, color: cs.primary),
            title: Text(l10n.shellPlaceholderSettingsRow),
            subtitle: Text(
              l10n.shellPlaceholderSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
