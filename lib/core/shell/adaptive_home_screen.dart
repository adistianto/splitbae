import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:splitbae/core/layout/app_breakpoints.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';
import 'package:splitbae/core/ocr/receipt_ocr_probe_provider.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/platform/platform_capabilities.dart';
import 'package:splitbae/core/shell/splitbae_apple_liquid_glass.dart';
import 'package:splitbae/core/theme/splitbae_shell_tokens.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/balances_screen.dart';
import 'package:splitbae/screens/bills_screen.dart';
import 'package:splitbae/screens/draft_split_screen.dart';
import 'package:splitbae/screens/scan_receipt_screen.dart';
import 'package:splitbae/screens/settings_screen.dart';
import 'package:splitbae/widgets/add_transaction_sheet.dart';
import 'package:splitbae/widgets/shell/splitbae_adaptive_bottom_nav.dart';
import 'package:splitbae/widgets/shell/splitbae_shell_chrome_button.dart';
import 'package:splitbae/widgets/shell/splitbae_shell_search_field.dart';
import 'package:splitbae/widgets/splitbae_fab_menu.dart';
import 'package:splitbae/widgets/splitbae_v0_user_menu.dart';

/// Root shell: **v0 IA** (Bills · Balances, FAB, scan) with **native** chrome —
/// Material 3 expressive on Android; **Liquid Glass** shell tokens on Apple
/// ([SplitBaeShellTokens]).
///
/// **Compact**: bottom nav + floating search/profile + FAB. **Expanded**: nav
/// rail (+ Liquid Glass Easy lens on Apple) + content + hinge-aware padding for
/// foldables ([hingeAwarePadding]).
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
  bool _scanOverlayOpen = false;
  late final TextEditingController _shellSearchController;
  final LiquidGlassViewController _appleLiquidGlassController =
      LiquidGlassViewController();

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
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.expandedMin;
    if (!wide) {
      setState(() => _scanOverlayOpen = true);
      return;
    }

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

  void _closeScanOverlay() {
    if (!mounted) return;
    setState(() => _scanOverlayOpen = false);
  }

  void _openDraftAfterScanImport() {
    _closeScanOverlay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = hostPlatformIsApple()
          ? CupertinoPageRoute<void>(
              builder: (_) => const DraftSplitScreen(),
            )
          : MaterialPageRoute<void>(
              builder: (_) => const DraftSplitScreen(),
            );
      Navigator.of(context).push(route);
    });
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
              _shellChromeVisible && !filtersOpen && !_scanOverlayOpen;
          final appleLg = splitBaeAppleLiquidGlassChromeEnabled(context);

          final bodyStack = Stack(
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
                        SplitBaeShellChromeIconButton(
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
                        SplitBaeShellChromeIconButton(
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
                  child: SplitBaeShellSearchField(
                    controller: _shellSearchController,
                    hintText: _bottomTabIndex == 0
                        ? l10n.billsSearchHint
                        : l10n.balancesSearchPeopleHint,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              SplitBaeFabMenu(
                onNewBill: _openNewBillSheet,
                onScanBill: _openScanBill,
                onCreateReport: () => setState(() => _bottomTabIndex = 1),
                visible: _shellChromeVisible && !_scanOverlayOpen,
              ),
              if (_scanOverlayOpen)
                Positioned.fill(
                  child: PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) {
                      if (!didPop) _closeScanOverlay();
                    },
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: Consumer(
                        builder: (context, ref, _) => ScanReceiptScreen(
                          currencyCode: ref.read(draftBillCurrencyProvider),
                          openDraftAfterBatchAdd: true,
                          onAddAllLines: (candidates) =>
                              _addOcrLinesToDraft(ref, candidates),
                          onDismiss: _closeScanOverlay,
                          onNavigateToDraft: _openDraftAfterScanImport,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );

          final Widget body;
          if (appleLg && !_scanOverlayOpen) {
            final h = splitBaeAppleBottomBarLensHeight(context);
            body = splitBaeAppleLiquidGlassViewport(
              controller: _appleLiquidGlassController,
              background: bodyStack,
              lenses: [
                splitBaeAppleBottomTabBarLens(
                  width: width,
                  height: h,
                  child: Material(
                    color: Colors.transparent,
                    child: SplitBaeAdaptiveBottomNav(
                      selectedIndex: _bottomTabIndex,
                      onDestinationSelected: (i) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _bottomTabIndex = i;
                          _shellSearchOpen = false;
                          _shellSearchController.clear();
                        });
                        ref.read(v0ShellSearchQueryProvider.notifier).state =
                            '';
                      },
                      destinations: [
                        SplitBaeAdaptiveBottomNavDestination(
                          icon: Icons.receipt_long_outlined,
                          selectedIcon: Icons.receipt_long,
                          label: l10n.navBillsTab,
                        ),
                        SplitBaeAdaptiveBottomNavDestination(
                          icon: Icons.account_balance_wallet_outlined,
                          selectedIcon: Icons.account_balance_wallet,
                          label: l10n.balancesTitle,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            body = bodyStack;
          }

          return Scaffold(
            body: body,
            bottomNavigationBar: _scanOverlayOpen
                ? null
                : (appleLg
                    ? null
                    : SplitBaeAdaptiveBottomNav(
                        selectedIndex: _bottomTabIndex,
                        onDestinationSelected: (i) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _bottomTabIndex = i;
                            _shellSearchOpen = false;
                            _shellSearchController.clear();
                          });
                          ref.read(v0ShellSearchQueryProvider.notifier).state =
                              '';
                        },
                        destinations: [
                          SplitBaeAdaptiveBottomNavDestination(
                            icon: Icons.receipt_long_outlined,
                            selectedIcon: Icons.receipt_long,
                            label: l10n.navBillsTab,
                          ),
                          SplitBaeAdaptiveBottomNavDestination(
                            icon: Icons.account_balance_wallet_outlined,
                            selectedIcon: Icons.account_balance_wallet,
                            label: l10n.balancesTitle,
                          ),
                        ],
                      )),
          );
        }

        final cs = Theme.of(context).colorScheme;
        final m3e = context.m3e;
        final appleLg = splitBaeAppleLiquidGlassChromeEnabled(context);
        final railW =
            splitBaeAppleRailLensWidth(context, expanded: railExtended);

        final navRail = NavigationRailM3E(
          type: railExtended
              ? NavigationRailM3EType.alwaysExpand
              : NavigationRailM3EType.alwaysCollapse,
          modality: NavigationRailM3EModality.standard,
          sections: [
            NavigationRailM3ESection(
              destinations: [
                NavigationRailM3EDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long),
                  label: l10n.navBillsTab,
                ),
                NavigationRailM3EDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(Icons.account_balance_wallet),
                  label: l10n.balancesTitle,
                ),
                NavigationRailM3EDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: l10n.settings,
                ),
              ],
            ),
          ],
          selectedIndex: _railIndex,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            setState(() => _railIndex = i);
          },
          labelBehavior: railExtended
              ? NavigationRailM3ELabelBehavior.alwaysShow
              : NavigationRailM3ELabelBehavior.onlySelected,
          background: Colors.transparent,
          scrollable: false,
        );

        final mainStack = Stack(
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
                onCreateReport: () => setState(() => _railIndex = 1),
                visible: _shellChromeVisible,
              ),
          ],
        );

        if (appleLg) {
          final h = constraints.maxHeight;
          return Scaffold(
            backgroundColor: cs.surface,
            body: splitBaeAppleLiquidGlassViewport(
              controller: _appleLiquidGlassController,
              background: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: railW),
                  Container(width: 1, color: m3e.colors.outlineVariant),
                  Expanded(child: mainStack),
                ],
              ),
              lenses: [
                splitBaeAppleNavigationRailLens(
                  width: railW,
                  height: h,
                  child: Material(
                    color: Colors.transparent,
                    child: navRail,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: cs.surface,
          body: Row(
            children: [
              navRail,
              Container(width: 1, color: m3e.colors.outlineVariant),
              Expanded(child: mainStack),
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
