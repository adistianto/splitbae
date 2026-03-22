import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:splitbae/core/data/amount_minor.dart' as amt_minor;
import 'package:splitbae/core/layout/adaptive_insets.dart';
import 'package:splitbae/core/layout/app_breakpoints.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/shell/splitbae_apple_liquid_glass.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/features/split/application/draft_split_provider.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/balances_screen.dart';
import 'package:splitbae/screens/settings_screen.dart';
import 'package:splitbae/src/rust/api/receipt_split.dart';
import 'package:splitbae/src/rust/api/simple.dart';
import 'package:splitbae/widgets/add_participant_sheet.dart';
import 'package:splitbae/widgets/add_receipt_item_sheet.dart';
import 'package:splitbae/widgets/confirm_delete_line.dart';
import 'package:splitbae/widgets/item_assignee_chips.dart';
import 'package:splitbae/widgets/manage_participants_sheet.dart';
import 'package:splitbae/widgets/post_bill_sheet.dart';
import 'package:splitbae/widgets/who_paid_sheet.dart';

/// Opens the draft split workspace (v0: full-screen flow from Bills, not a tab).
/// Opens the post-bill sheet; shows save progress on this button via [postBillInFlightProvider].
class _PostBillTonalButton extends ConsumerWidget {
  const _PostBillTonalButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posting = ref.watch(postBillInFlightProvider);
    return FilledButton.tonal(
      onPressed: posting
          ? null
          : () {
              HapticFeedback.mediumImpact();
              showPostBillSheet(context, ref);
            },
      child: posting
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(label),
              ],
            )
          : Text(label),
    ).animate(target: posting ? 1 : 0).shimmer(
          duration: 950.ms,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
        );
  }
}

void openDraftSplitScreen(
  BuildContext context,
  WidgetRef ref, {
  bool openAddItemSheetAfter = false,
}) {
  final route = hostPlatformIsApple()
      ? CupertinoPageRoute<void>(builder: (_) => const DraftSplitScreen())
      : MaterialPageRoute<void>(builder: (_) => const DraftSplitScreen());
  Navigator.of(context).push(route).then((_) {
    if (!context.mounted || !openAddItemSheetAfter) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showAddReceiptItemSheet(context, ref);
    });
  });
}

/// In-progress bill (draft lines, split, post) — v0 “compose” workspace.
class DraftSplitScreen extends ConsumerWidget {
  const DraftSplitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hPad = splitBaePageHorizontalPadding(context);
    final width = MediaQuery.sizeOf(context).width;
    final twoPane = width >= AppBreakpoints.twoPaneMin;

    return Scaffold(
      appBar: splitBaeAdaptiveAppBar(
        context: context,
        title: l10n.navSplitTitle,
        actions: [
          splitBaeAdaptiveToolbarIcon(
            context: context,
            tooltip: l10n.balancesTooltip,
            icon: PhosphorIconsRegular.wallet,
            onPressed: () => openBalancesScreen(context),
          ),
          splitBaeAdaptiveToolbarIcon(
            context: context,
            tooltip: l10n.peopleTooltip,
            icon: PhosphorIconsRegular.usersThree,
            onPressed: () => showManageParticipantsSheet(context, ref),
          ),
          splitBaeAdaptiveToolbarIcon(
            context: context,
            tooltip: l10n.whoPaidTooltip,
            icon: PhosphorIconsRegular.bank,
            onPressed: () => showWhoPaidSheet(context, ref),
          ),
          splitBaeAdaptiveToolbarIcon(
            context: context,
            tooltip: l10n.addItemTooltip,
            icon: PhosphorIconsRegular.shoppingCart,
            onPressed: () => showAddReceiptItemSheet(context, ref),
          ),
          splitBaeAdaptiveToolbarIcon(
            context: context,
            tooltip: l10n.settings,
            icon: PhosphorIconsRegular.gearSix,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _DraftSplitBody(horizontalPadding: hPad, twoPane: twoPane),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await showAddParticipantSheet(context);
          },
          label: Text(l10n.addPerson),
          icon: Icon(PhosphorIconsRegular.userPlus),
        ),
      ),
    );
  }
}

class _DraftSplitBody extends ConsumerWidget {
  const _DraftSplitBody({
    required this.horizontalPadding,
    required this.twoPane,
  });

  final double horizontalPadding;
  final bool twoPane;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(itemsProvider);
    final splitAsync = ref.watch(splitResultProvider);
    final names = ref.watch(draftSplitOwedDisplayNamesProvider);
    final locale = Localizations.localeOf(context);
    final activeAsync = ref.watch(draftBillActiveParticipantsProvider);
    final currency = ref.watch(draftBillCurrencyProvider);
    final adj = ref.watch(draftSplitNotifierProvider);

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final summaryCoreH = 56.0 + bottomInset;
    final splitRows = splitAsync.maybeWhen(
      data: (rows) => rows.length.clamp(1, 8),
      orElse: () => 1,
    );
    final summaryBarHeight = summaryCoreH + 28.0 * splitRows;

    final scrollPad = twoPane
        ? EdgeInsets.zero
        : EdgeInsets.only(bottom: summaryBarHeight + 12);

    final billSlivers = <Widget>[
      SliverPadding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 4),
        sliver: SliverToBoxAdapter(
          child: Text(
            l10n.splitSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
      if (items.isNotEmpty && ref.watch(participantsProvider).isNotEmpty)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 4),
          sliver: SliverToBoxAdapter(
            child: _PostBillTonalButton(label: l10n.postBillAction),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 8),
        sliver: SliverToBoxAdapter(
          child: Text(l10n.billItemsTitle, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
        sliver: SliverToBoxAdapter(
          child: _TaxTipRow(
            currencyCode: currency,
            taxMinor: adj.taxAmountMinor,
            tipMinor: adj.tipAmountMinor,
            onEdit: () => _showTaxTipSheet(context, ref),
          ),
        ),
      ),
      if (items.isEmpty)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.emptyBillHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final line = items[index];
              return Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
                child: _DraftLineCard(
                  line: line,
                  horizontalPadding: horizontalPadding,
                  locale: locale,
                  onDelete: () => confirmDeleteLine(context, ref, line),
                  onEdit: () => showAddReceiptItemSheet(context, ref, existingLine: line),
                ),
              );
            },
            childCount: items.length,
          ),
        ),
      SliverPadding(padding: scrollPad, sliver: const SliverToBoxAdapter(child: SizedBox.shrink())),
    ];

    final splitPane = _SplitSummaryPane(
      horizontalPadding: horizontalPadding,
      splitAsync: splitAsync,
      names: names,
      locale: locale,
    );

    final scrollOnly = activeAsync.when(
      data: (_) => twoPane
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CustomScrollView(slivers: billSlivers),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            l10n.perPersonTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: splitPane),
                    ],
                  ),
                ),
              ],
            )
          : CustomScrollView(slivers: billSlivers),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );

    final pinnedSummary = _PinnedSplitSummaryBar(
      title: l10n.draftSplitPinnedSummaryTitle,
      splitAsync: splitAsync,
      names: names,
      locale: locale,
      errorLabel: l10n.draftSplitCalculateError,
    );

    final useAppleGlass =
        hostPlatformIsApple() && splitBaeAppleLiquidGlassChromeEnabled(context);

    if (twoPane) {
      return scrollOnly;
    }

    if (useAppleGlass) {
      final w = MediaQuery.sizeOf(context).width;
      return splitBaeAppleLiquidGlassViewport(
        background: scrollOnly,
        lenses: [
          LiquidGlass(
            width: w,
            height: summaryBarHeight,
            position: const LiquidGlassOffsetPosition(left: 0, right: 0, bottom: 0),
            magnification: 1.03,
            refractionMode: LiquidGlassRefractionMode.shapeRefraction,
            distortion: 0.14,
            distortionWidth: 34,
            chromaticAberration: 0.006,
            saturation: 1.05,
            blur: const LiquidGlassBlur(sigmaX: 0.38, sigmaY: 0.38),
            color: const Color(0x14FFFFFF),
            shape: RoundedRectangleShape(
              cornerRadius: 26,
              borderWidth: 1.4,
              borderSoftness: 2.4,
              lightIntensity: 1.5,
              oneSideLightIntensity: 1.2,
              lightDirection: 42,
              lightMode: LiquidGlassLightMode.edge,
              lightColor: const Color(0xD9FFFFFF),
              shadowColor: const Color(0x33000000),
            ),
            draggable: false,
            outOfBoundaries: false,
            child: pinnedSummary,
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        scrollOnly,
        pinnedSummary,
      ],
    );
  }
}

class _TaxTipRow extends StatelessWidget {
  const _TaxTipRow({
    required this.currencyCode,
    required this.taxMinor,
    required this.tipMinor,
    required this.onEdit,
  });

  final String currencyCode;
  final int taxMinor;
  final int tipMinor;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final taxStr = formatCurrencyAmount(
      amount: amt_minor.minorUnitsToAmount(taxMinor, currencyCode),
      currencyCode: currencyCode,
      locale: locale,
    );
    final tipStr = formatCurrencyAmount(
      amount: amt_minor.minorUnitsToAmount(tipMinor, currencyCode),
      currencyCode: currencyCode,
      locale: locale,
    );
    final m3e = context.m3e;
    return Material(
      color: m3e.colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: m3e.colors.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: ListTile(
        leading: Icon(PhosphorIconsRegular.receipt, color: Theme.of(context).colorScheme.primary),
        title: Text(
          '${l10n.draftSplitTaxFieldLabel} · ${l10n.draftSplitTipFieldLabel}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$taxStr · $tipStr'),
        trailing: IconButton(
          onPressed: onEdit,
          icon: Icon(PhosphorIconsRegular.pencilSimple),
        ),
      ),
    );
  }
}

Future<void> _showTaxTipSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final adj = ref.read(draftSplitNotifierProvider);
  final currency = ref.read(draftBillCurrencyProvider);
  final taxCtrl = TextEditingController(
    text: amt_minor.amountToInputText(
      amt_minor.minorUnitsToAmount(adj.taxAmountMinor, currency),
      currency,
    ),
  );
  final tipCtrl = TextEditingController(
    text: amt_minor.amountToInputText(
      amt_minor.minorUnitsToAmount(adj.tipAmountMinor, currency),
      currency,
    ),
  );
  try {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addTransactionTaxSummaryLine, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: taxCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.draftSplitTaxFieldLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tipCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.draftSplitTipFieldLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final tax = double.tryParse(taxCtrl.text.replaceAll(',', '.')) ?? 0;
                  final tip = double.tryParse(tipCtrl.text.replaceAll(',', '.')) ?? 0;
                  ref.read(draftSplitNotifierProvider.notifier).setTaxAmountMinor(
                        amt_minor.amountToMinorUnits(tax, currency),
                      );
                  ref.read(draftSplitNotifierProvider.notifier).setTipAmountMinor(
                        amt_minor.amountToMinorUnits(tip, currency),
                      );
                  Navigator.of(ctx).pop();
                },
                child: Text(l10n.addTransactionApplySuggestion),
              ),
            ],
          ),
        );
      },
    );
  } finally {
    taxCtrl.dispose();
    tipCtrl.dispose();
  }
}

class _DraftLineCard extends ConsumerWidget {
  const _DraftLineCard({
    required this.line,
    required this.horizontalPadding,
    required this.locale,
    required this.onDelete,
    required this.onEdit,
  });

  final LedgerLineItem line;
  final double horizontalPadding;
  final Locale locale;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final m3e = context.m3e;
    final scheme = Theme.of(context).colorScheme;
    final amountStr = formatCurrencyAmount(
      amount: line.receiptItem.price,
      currencyCode: line.receiptItem.currencyCode,
      locale: locale,
    );
    final unitStr = formatCurrencyAmount(
      amount: line.unitPrice,
      currencyCode: line.receiptItem.currencyCode,
      locale: locale,
    );
    final participantsAsync = ref.watch(draftBillActiveParticipantsProvider);

    return Semantics(
      label: l10n.semanticsDraftBillLine(line.receiptItem.name, amountStr),
      hint: l10n.semanticsDraftLineHint,
      button: true,
      child: Material(
        color: m3e.colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: m3e.colors.outlineVariant.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            line.receiptItem.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        splitBaeAdaptiveToolbarIcon(
                          context: context,
                          tooltip: l10n.deleteAction,
                          icon: PhosphorIconsRegular.trash,
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _DraftLineMetric(
                            label: l10n.draftBillLineQtyColumn,
                            value: '${line.quantity}',
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _DraftLineMetric(
                            label: l10n.draftBillLineUnitColumn,
                            value: unitStr,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _DraftLineMetric(
                            label: l10n.draftBillLineLineTotalColumn,
                            value: amountStr,
                            emphasize: true,
                            valueColor: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        line.receiptItem.currencyCode,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: participantsAsync.when(
                data: (participants) => ItemAssigneeChips(
                  participants: participants,
                  assigneeIds: line.assignedParticipantIds.toSet(),
                  dense: true,
                  onAssigneesChanged: (ids) {
                    ref.read(itemsProvider.notifier).setLineAssignments(
                          lineId: line.id,
                          selectedParticipantIds: ids,
                        );
                  },
                ),
                loading: () => const SizedBox(height: 8),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftLineMetric extends StatelessWidget {
  const _DraftLineMetric({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vc = valueColor ?? scheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: (emphasize
                  ? Theme.of(context).textTheme.titleSmall
                  : Theme.of(context).textTheme.bodyMedium)
              ?.copyWith(
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: vc,
              ),
        ),
      ],
    );
  }
}

/// Scrollable per-person block (two-pane right column or single-pane above pinned bar).
class _SplitSummaryPane extends StatelessWidget {
  const _SplitSummaryPane({
    required this.horizontalPadding,
    required this.splitAsync,
    required this.names,
    required this.locale,
  });

  final double horizontalPadding;
  final AsyncValue<List<UserOwedMinor>> splitAsync;
  final Map<String, String> names;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return splitAsync.when(
      data: (rows) {
        if (rows.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
            child: Text(
              AppLocalizations.of(context)!.emptyParticipantsHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final row in rows)
              _OwedRow(
                horizontalPadding: horizontalPadding,
                owed: row,
                displayName: names[row.userId] ?? row.userId,
                locale: locale,
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Text('${AppLocalizations.of(context)!.draftSplitCalculateError} $e'),
      ),
    );
  }
}

class _OwedRow extends StatelessWidget {
  const _OwedRow({
    required this.horizontalPadding,
    required this.owed,
    required this.displayName,
    required this.locale,
  });

  final double horizontalPadding;
  final UserOwedMinor owed;
  final String displayName;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final m3e = context.m3e;
    final formatted = formatCurrencyAmount(
      amount: minorUnitsToAmount(
        minor: owed.amountMinor,
        currencyCode: owed.currencyCode,
      ),
      currencyCode: owed.currencyCode,
      locale: locale,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 6),
      child: Material(
        color: m3e.colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: m3e.colors.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              splitBaeInitialGrapheme(displayName),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(
            displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(owed.currencyCode, style: Theme.of(context).textTheme.bodySmall),
          trailing: Text(
            formatted,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      ),
    );
  }
}

/// Pinned bottom bar: live [calculateSplit] totals only. On Apple + LG, wrapped as a [LiquidGlass] lens.
class _PinnedSplitSummaryBar extends StatelessWidget {
  const _PinnedSplitSummaryBar({
    required this.title,
    required this.splitAsync,
    required this.names,
    required this.locale,
    required this.errorLabel,
  });

  final String title;
  final AsyncValue<List<UserOwedMinor>> splitAsync;
  final Map<String, String> names;
  final Locale locale;
  final String errorLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: hostPlatformIsApple()
          ? Colors.transparent
          : scheme.surfaceContainerHigh.withValues(alpha: 0.96),
      elevation: hostPlatformIsApple() ? 0 : 3,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
          child: splitAsync.when(
            data: (rows) {
              if (rows.isEmpty) {
                return Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 6),
                  ...rows.map(
                    (owed) {
                      final name = names[owed.userId] ?? owed.userId;
                      final formatted = formatCurrencyAmount(
                        amount: minorUnitsToAmount(
                          minor: owed.amountMinor,
                          currencyCode: owed.currencyCode,
                        ),
                        currencyCode: owed.currencyCode,
                        locale: locale,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Text(
                              formatted,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Text(
              '$errorLabel $e',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
        ),
      ),
    );
  }
}
