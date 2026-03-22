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
import 'package:splitbae/widgets/splitbae_fab_menu.dart';
import 'package:splitbae/widgets/splitbae_v0_bottom_nav.dart';
import 'package:splitbae/widgets/splitbae_v0_chrome.dart';
import 'package:splitbae/widgets/splitbae_v0_user_menu.dart';

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
  bool _shellChromeVisible = true;
  bool _shellSearchOpen = false;
  late final TextEditingController _shellSearchController;

  bool _onShellScroll(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return false;
    final d = n.scrollDelta ?? 0;
    final px = n.metrics.pixels;
    if (px < 16) {
      if (!_shellChromeVisible) setState(() => _shellChromeVisible = true);
      return false;
    }
    if (d > 3) {
      if (_shellChromeVisible) {
        setState(() {
          _shellChromeVisible = false;
          _shellSearchOpen = false;
        });
      }
    } else if (d < -3) {
      if (!_shellChromeVisible) setState(() => _shellChromeVisible = true);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _shellSearchController = TextEditingController();
    _shellSearchController.addListener(() {
      ref.read(v0ShellSearchQueryProvider.notifier).state =
          _shellSearchController.text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(receiptOcrProbeProvider.future));
    });
  }

  @override
  void dispose() {
    _shellSearchController.dispose();
    super.dispose();
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
    ref.listen<String>(v0ShellSearchQueryProvider, (prev, next) {
      if (next.isEmpty && _shellSearchController.text.isNotEmpty) {
        _shellSearchController.clear();
      }
    });

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
          final topPad = MediaQuery.paddingOf(context).top;
          final filtersOpen = ref.watch(v0BillsFiltersSheetOpenProvider);
          final showFloatingChrome =
              _shellChromeVisible && !filtersOpen;
          final cs = Theme.of(context).colorScheme;

          return Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: _onShellScroll,
                  child: IndexedStack(
                    index: _bottomTabIndex,
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContent),
                          child: Padding(
                            padding: hinge,
                            child: BillsScreen(
                              v0ShellMode: true,
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
                ),
                if (showFloatingChrome)
                  Positioned(
                    top: topPad + 8,
                    right: 16,
                    child: AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 220),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SplitBaeV0CircleIconButton(
                            icon: _shellSearchOpen ? Icons.close : Icons.search,
                            semanticLabel: _shellSearchOpen
                                ? MaterialLocalizations.of(context)
                                    .closeButtonLabel
                                : l10n.billsSearchHint,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _shellSearchOpen = !_shellSearchOpen;
                                if (!_shellSearchOpen) {
                                  _shellSearchController.clear();
                                  ref
                                      .read(v0ShellSearchQueryProvider.notifier)
                                      .state = '';
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          SplitBaeV0CircleIconButton(
                            icon: Icons.person_outline,
                            semanticLabel: l10n.v0UserMenuTitle,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              showSplitBaeV0UserMenu(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_shellSearchOpen && showFloatingChrome)
                  Positioned(
                    top: topPad + 56,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(16),
                      color: cs.surface,
                      child: TextField(
                        controller: _shellSearchController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: _bottomTabIndex == 0
                              ? l10n.billsSearchHint
                              : l10n.balancesSearchPeopleHint,
                          prefixIcon: const Icon(Icons.search, size: 22),
                          suffixIcon: _shellSearchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _shellSearchController.clear();
                                      ref
                                          .read(
                                            v0ShellSearchQueryProvider.notifier,
                                          )
                                          .state = '';
                                    });
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: cs.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: cs.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: cs.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                SplitBaeFabMenu(
                  onNewBill: _openNewBillSheet,
                  onScanBill: _openScanBill,
                  onCreateReport: () => setState(() => _bottomTabIndex = 1),
                  visible: _shellChromeVisible,
                ),
              ],
            ),
            bottomNavigationBar: SplitBaeV0BottomNav(
              selectedIndex: _bottomTabIndex,
              onDestinationSelected: (i) {
                HapticFeedback.selectionClick();
                setState(() {
                  _bottomTabIndex = i;
                  _shellSearchOpen = false;
                  _shellSearchController.clear();
                });
                ref.read(v0ShellSearchQueryProvider.notifier).state = '';
              },
              destinations: [
                SplitBaeV0BottomNavDestination(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  label: l10n.navBillsTab,
                ),
                SplitBaeV0BottomNavDestination(
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet,
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: _onShellScroll,
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
                              : const SafeArea(
                                  child: SettingsScreen(embedded: true),
                                ),
                    ),
                    if (_railIndex != 2)
                      SplitBaeFabMenu(
                        onNewBill: _openNewBillSheet,
                        onScanBill: _openScanBill,
                        onCreateReport: () =>
                            setState(() => _railIndex = 1),
                        visible: _shellChromeVisible,
                      ),
                  ],
                ),
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
