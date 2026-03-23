import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:splitbae/core/layout/app_breakpoints.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/platform/platform_capabilities.dart';
import 'package:splitbae/core/shell/splitbae_apple_liquid_glass.dart';
import 'package:splitbae/core/shell/splitbae_shell_placeholders.dart';
import 'package:splitbae/core/theme/splitbae_v0_ui_contract.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/screens/bills_screen.dart';
import 'package:splitbae/widgets/shell/splitbae_shell_chrome_button.dart';
import 'package:splitbae/widgets/shell/splitbae_shell_search_field.dart';

/// **UI-only** adaptive shell: v0 IA (Bills · Balances, FAB, search, profile) —
/// compact [NavigationBarM3E], wide [NavigationRailM3E] + Settings. **M3 Expressive**
/// via **m3e_collection** on Android; on Apple, **Liquid Glass Easy** lenses for
/// tab bar + rail ([splitBaeAppleLiquidGlassViewport]) — no [BackdropFilter] shell
/// blur. No Riverpod / business logic — swap [home] in [MaterialApp] for
/// [AdaptiveHomeScreen] when wiring features.
class SplitBaeAppShell extends StatefulWidget {
  const SplitBaeAppShell({super.key});

  @override
  State<SplitBaeAppShell> createState() => _SplitBaeAppShellState();
}

class _SplitBaeAppShellState extends State<SplitBaeAppShell> {
  int _railIndex = 0;
  int _bottomTabIndex = 0;
  bool _chromeVisible = true;
  bool _searchOpen = false;
  bool _scanOpen = false;
  late final TextEditingController _searchCtrl;
  final LiquidGlassViewController _appleLiquidGlassController =
      LiquidGlassViewController();

  bool _onScroll(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return false;
    final d = n.scrollDelta ?? 0;
    final px = n.metrics.pixels;
    if (px < 16) {
      if (!_chromeVisible) setState(() => _chromeVisible = true);
      return false;
    }
    if (d > 3) {
      if (_chromeVisible) {
        setState(() {
          _chromeVisible = false;
          _searchOpen = false;
        });
      }
    } else if (d < -3) {
      if (!_chromeVisible) setState(() => _chromeVisible = true);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _profileSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.v0UserMenuTitle,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.shellPlaceholderSubtitle,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _openSettingsShortcut() {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= AppBreakpoints.expandedMin) {
      setState(() => _railIndex = 2);
    } else {
      _toast(AppLocalizations.of(context)!.shellPlaceholderSubtitle);
    }
  }

  Widget _fabMenu(
    AppLocalizations l10n, {
    required bool visible,
    required VoidCallback onNewBill,
    required VoidCallback onScanBill,
    required VoidCallback onCreateReport,
  }) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      right: 20,
      bottom: SplitBaeV0Layout.fabBottomNavReserve + bottomSafe,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: !visible,
          child: FabMenuM3E(
            primaryFab: FabM3E(
              icon: Icon(PhosphorIconsRegular.plus),
              tooltip: l10n.fabNewBill,
            ),
            items: [
              FabMenuItem(
                icon: const Icon(Icons.description_outlined),
                label: Text(l10n.fabCreateReport),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onCreateReport();
                },
              ),
              FabMenuItem(
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.fabScanBill),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onScanBill();
                },
              ),
              FabMenuItem(
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(l10n.fabNewBill),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onNewBill();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactBottomBar(AppLocalizations l10n) {
    return NavigationBarM3E(
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedIndex: _bottomTabIndex,
      onDestinationSelected: (i) {
        HapticFeedback.selectionClick();
        setState(() {
          _bottomTabIndex = i;
          _searchOpen = false;
          _searchCtrl.clear();
        });
      },
      destinations: [
        NavigationDestinationM3E(
          icon: Icon(PhosphorIconsRegular.receipt),
          selectedIcon: Icon(PhosphorIconsFill.receipt),
          label: l10n.navBillsTab,
        ),
        NavigationDestinationM3E(
          icon: Icon(PhosphorIconsRegular.wallet),
          selectedIcon: Icon(PhosphorIconsFill.wallet),
          label: l10n.balancesTitle,
        ),
      ],
    );
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
        final appleLg = splitBaeAppleLiquidGlassChromeEnabled(context);

        if (!useRail) {
          final maxContent = wc == AppWindowClass.medium
              ? 720.0
              : double.infinity;
          final topPad = MediaQuery.paddingOf(context).top;
          final showChrome = _chromeVisible && !_scanOpen;
          final showShellSearch = showChrome && _bottomTabIndex == 1;
          final cs = Theme.of(context).colorScheme;

          final bodyStack = Stack(
            fit: StackFit.expand,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: IndexedStack(
                  index: _bottomTabIndex,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContent),
                        child: Padding(
                          padding: hinge,
                          child: BillsScreen(
                            v0ShellMode: false,
                            onNewBill: () => _toast(l10n.fabNewBill),
                            onScanBillEntry: () => setState(() {}),
                            onSwitchToBalances: () =>
                                setState(() => _bottomTabIndex = 1),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContent),
                        child: Padding(
                          padding: hinge,
                          child: const ShellBalancesPlaceholder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showChrome)
                Positioned(
                  top: topPad + 12,
                  right: 16,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    offset: _chromeVisible
                        ? Offset.zero
                        : const Offset(0, -0.25),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _chromeVisible ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_chromeVisible,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showShellSearch)
                              SplitBaeShellChromeIconButton(
                                icon: _searchOpen
                                    ? PhosphorIconsRegular.x
                                    : PhosphorIconsRegular.magnifyingGlass,
                                semanticLabel: _searchOpen
                                    ? MaterialLocalizations.of(
                                        context,
                                      ).closeButtonLabel
                                    : l10n.balancesSearchPeopleHint,
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _searchOpen = !_searchOpen;
                                    if (!_searchOpen) _searchCtrl.clear();
                                  });
                                },
                              ),
                            if (showShellSearch) const SizedBox(width: 8),
                            SplitBaeShellChromeIconButton(
                              icon: PhosphorIconsRegular.user,
                              semanticLabel: l10n.v0UserMenuTitle,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _profileSheet();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_searchOpen && showShellSearch)
                Positioned(
                  top: topPad + 56,
                  left: 16,
                  right: 16,
                  child: SplitBaeShellSearchField(
                    controller: _searchCtrl,
                    hintText: l10n.balancesSearchPeopleHint,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              _fabMenu(
                l10n,
                visible: _chromeVisible && !_scanOpen,
                onNewBill: () => _toast(l10n.fabNewBill),
                onScanBill: () => setState(() => _scanOpen = true),
                onCreateReport: () => setState(() => _bottomTabIndex = 1),
              ),
              if (_scanOpen)
                Positioned.fill(
                  child: PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (d, _) {
                      if (!d) setState(() => _scanOpen = false);
                    },
                    child: _ScanShellOverlay(
                      onClose: () => setState(() => _scanOpen = false),
                    ),
                  ),
                ),
            ],
          );

          final Widget body;
          if (appleLg && !_scanOpen) {
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
                    child: _compactBottomBar(l10n),
                  ),
                ),
              ],
            );
          } else {
            body = bodyStack;
          }

          return Scaffold(
            backgroundColor: cs.surface,
            body: body,
            bottomNavigationBar: _scanOpen
                ? null
                : (appleLg
                      ? null
                      : _compactBottomBar(l10n)),
          );
        }

        final cs = Theme.of(context).colorScheme;
        final m3e = context.m3e;
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
                  icon: Icon(PhosphorIconsRegular.receipt),
                  selectedIcon: Icon(PhosphorIconsFill.receipt),
                  label: l10n.navBillsTab,
                ),
                NavigationRailM3EDestination(
                  icon: Icon(PhosphorIconsRegular.wallet),
                  selectedIcon: Icon(PhosphorIconsFill.wallet),
                  label: l10n.balancesTitle,
                ),
                NavigationRailM3EDestination(
                  icon: Icon(PhosphorIconsRegular.gear),
                  selectedIcon: Icon(PhosphorIconsFill.gear),
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
              onNotification: _onScroll,
              child: _railIndex == 0
                  ? Padding(
                      padding: hinge,
                      child: BillsScreen(
                        v0ShellMode: false,
                        onNewBill: () => _toast(l10n.fabNewBill),
                        onScanBillEntry: () => setState(() {}),
                        onSwitchToBalances: () =>
                            setState(() => _bottomTabIndex = 1),
                      ),
                    )
                  : _railIndex == 1
                  ? Padding(
                      padding: hinge,
                      child: const ShellBalancesPlaceholder(),
                    )
                  : const SafeArea(child: ShellSettingsPlaceholder()),
            ),
            if (_railIndex != 2)
              _fabMenu(
                l10n,
                visible: _chromeVisible,
                onNewBill: () => _toast(l10n.fabNewBill),
                onScanBill: () => _toast(l10n.fabScanBill),
                onCreateReport: () => setState(() => _railIndex = 1),
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
              _ShellOpenSettingsIntent(),
          SingleActivator(LogicalKeyboardKey.comma, control: true):
              _ShellOpenSettingsIntent(),
        },
        child: Actions(
          actions: {
            _ShellOpenSettingsIntent: CallbackAction<_ShellOpenSettingsIntent>(
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

class _ShellOpenSettingsIntent extends Intent {
  const _ShellOpenSettingsIntent();
}

/// Full-screen scan **shell** — content area is neutral; chrome is system/stack.
class _ScanShellOverlay extends StatelessWidget {
  const _ScanShellOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (hostPlatformIsApple()) {
      return CupertinoPageScaffold(
        backgroundColor: cs.surface,
        navigationBar: CupertinoNavigationBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onClose,
            child: Icon(CupertinoIcons.xmark, color: cs.onSurface),
          ),
          middle: Text(l10n.fabScanBill),
        ),
        child: SafeArea(
          child: Center(
            child: Text(
              l10n.shellPlaceholderSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBarM3E(
        automaticallyImplyLeading: false,
        leading: IconButtonM3E(
          icon: const Icon(Icons.close),
          onPressed: onClose,
          tooltip: MaterialLocalizations.of(context).closeButtonLabel,
        ),
        titleText: l10n.fabScanBill,
      ),
      body: Center(
        child: Text(
          l10n.shellPlaceholderSubtitle,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
