import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/layout/app_breakpoints.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/platform/platform_capabilities.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';
import 'package:splitbae/core/ocr/receipt_ocr_probe_provider.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/balances_screen.dart';
import 'package:splitbae/screens/bills_screen.dart';
import 'package:splitbae/screens/scan_receipt_screen.dart';
import 'package:splitbae/screens/settings_screen.dart';
import 'package:splitbae/widgets/add_transaction_sheet.dart';

/// Phone: **Bills · Balances** (v0-style). Draft split opens as a pushed screen.
/// Wide: rail **Bills · Balances · Settings**; compose opens [DraftSplitScreen] on a route.
class AdaptiveHomeScreen extends ConsumerStatefulWidget {
  const AdaptiveHomeScreen({super.key});

  @override
  ConsumerState<AdaptiveHomeScreen> createState() => _AdaptiveHomeScreenState();
}

class _AdaptiveHomeScreenState extends ConsumerState<AdaptiveHomeScreen> {
  int _railIndex = 0;
  int _bottomTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(receiptOcrProbeProvider.future));
    });
  }

  Future<void> _addOcrLinesToDraft(
    WidgetRef ref,
    List<ReceiptLineCandidate> candidates,
  ) async {
    final participants =
        await ref.read(draftBillActiveParticipantsProvider.future);
    final allIds = participants.map((e) => e.id).toSet();
    final notifier = ref.read(itemsProvider.notifier);
    for (final c in candidates) {
      final id = await notifier.addItem(
        c.label,
        c.amount,
        quantity: c.quantity ?? 1,
      );
      await notifier.setLineAssignments(
        lineId: id,
        selectedParticipantIds: allIds,
      );
    }
  }

  void _openScanBill() {
    Widget buildScan(WidgetRef ref) {
      return ScanReceiptScreen(
        currencyCode: ref.read(draftBillCurrencyProvider),
        openDraftAfterBatchAdd: true,
        onAddAllLines: (candidates) => _addOcrLinesToDraft(ref, candidates),
      );
    }

    if (hostPlatformIsApple()) {
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => Consumer(
            builder: (context, ref, _) => buildScan(ref),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => Consumer(
            builder: (context, ref, _) => buildScan(ref),
          ),
        ),
      );
    }
  }

  void _openNewBillSheet() {
    showAddTransactionSheet(context);
  }

  void _openSettingsShortcut() {
    if (!mounted) return;
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.expandedMin) {
      setState(() => _railIndex = 2);
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget shell = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wc = windowClassForWidth(width);
        final useRail = width >= AppBreakpoints.expandedMin;
        final railExtended = width >= AppBreakpoints.railExtendedLabelsMin;
        final hinge = hingeAwarePadding(context);

        if (!useRail) {
          final maxContent = wc == AppWindowClass.medium
              ? 720.0
              : double.infinity;

          return Scaffold(
            body: IndexedStack(
              index: _bottomTabIndex,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContent),
                    child: Padding(
                      padding: hinge,
                      child: BillsScreen(
                        onNewBill: _openNewBillSheet,
                        onScanBillEntry: _openScanBill,
                        onSwitchToBalances: () => setState(() {
                          _bottomTabIndex = 1;
                        }),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContent),
                    child: Padding(
                      padding: hinge,
                      child: const BalancesScreen(embedded: true),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _bottomTabIndex,
              onDestinationSelected: (i) {
                HapticFeedback.selectionClick();
                setState(() => _bottomTabIndex = i);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long),
                  label: l10n.navBillsTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(Icons.account_balance_wallet),
                  label: l10n.balancesTitle,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: railExtended,
                selectedIndex: _railIndex,
                onDestinationSelected: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _railIndex = i);
                },
                labelType: railExtended
                    ? NavigationRailLabelType.all
                    : NavigationRailLabelType.selected,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.receipt_long_outlined),
                    selectedIcon: const Icon(Icons.receipt_long),
                    label: Text(l10n.navBillsTab),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: const Icon(Icons.account_balance_wallet),
                    label: Text(l10n.balancesTitle),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.settings_outlined),
                    selectedIcon: const Icon(Icons.settings),
                    label: Text(l10n.settings),
                  ),
                ],
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: _railIndex == 0
                    ? Padding(
                        padding: hinge,
                        child: BillsScreen(
                          onNewBill: _openNewBillSheet,
                          onScanBillEntry: _openScanBill,
                          onSwitchToBalances: () => setState(() {
                            _railIndex = 1;
                          }),
                        ),
                      )
                    : _railIndex == 1
                        ? Padding(
                            padding: hinge,
                            child: const BalancesScreen(embedded: true),
                          )
                        : const SafeArea(child: SettingsScreen(embedded: true)),
              ),
            ],
          ),
        );
      },
    );

    if (isDesktopPlatform) {
      shell = Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.comma, meta: true):
              _OpenSettingsIntent(),
          SingleActivator(LogicalKeyboardKey.comma, control: true):
              _OpenSettingsIntent(),
        },
        child: Actions(
          actions: {
            _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
              onInvoke: (_) {
                _openSettingsShortcut();
                return null;
              },
            ),
          },
          child: Focus(autofocus: true, child: shell),
        ),
      );
    }
    return shell;
  }
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

/// Mouse / trackpad drag scrolling on desktop and web.
class SplitBaeScrollBehavior extends MaterialScrollBehavior {
  const SplitBaeScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}
