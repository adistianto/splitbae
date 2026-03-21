import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/layout/adaptive_insets.dart';
import 'package:splitbae/core/layout/app_breakpoints.dart';
import 'package:splitbae/core/platform/adaptive_confirm_dialog.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/platform/platform_capabilities.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/settings_screen.dart';
import 'package:splitbae/widgets/add_participant_sheet.dart';
import 'package:splitbae/widgets/add_receipt_item_sheet.dart';
import 'package:splitbae/widgets/manage_participants_sheet.dart';
import 'package:splitbae/widgets/split_home_content.dart';

Future<void> confirmDeleteLine(
  BuildContext context,
  WidgetRef ref,
  LedgerLineItem line,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showAdaptiveConfirmDialog(
    context: context,
    title: Text(l10n.deleteItemTitle),
    content: Text(l10n.deleteItemBody),
    cancelLabel: l10n.cancel,
    confirmLabel: l10n.deleteAction,
    confirmIsDestructive: true,
  );
  if (ok == true && context.mounted) {
    await ref.read(itemsProvider.notifier).deleteItem(line.id);
  }
}

/// Phone, fold, tablet, and desktop: navigation rail + optional two-pane split.
class AdaptiveHomeScreen extends ConsumerStatefulWidget {
  const AdaptiveHomeScreen({super.key});

  @override
  ConsumerState<AdaptiveHomeScreen> createState() => _AdaptiveHomeScreenState();
}

class _AdaptiveHomeScreenState extends ConsumerState<AdaptiveHomeScreen> {
  int _railIndex = 0;

  void _openSettingsShortcut() {
    if (!mounted) return;
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.expandedMin) {
      setState(() => _railIndex = 1);
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
        final twoPane = width >= AppBreakpoints.twoPaneMin;
        final railExtended = width >= AppBreakpoints.railExtendedLabelsMin;
        final hinge = hingeAwarePadding(context);

        final hPad = splitBaePageHorizontalPadding(context);

        if (!useRail) {
          final maxContent = wc == AppWindowClass.medium
              ? 720.0
              : double.infinity;
          final narrowActions = <Widget>[
            splitBaeAdaptiveToolbarIcon(
              context: context,
              tooltip: l10n.peopleTooltip,
              icon: Icons.group_outlined,
              onPressed: () => showManageParticipantsSheet(context, ref),
            ),
            splitBaeAdaptiveToolbarIcon(
              context: context,
              tooltip: l10n.addItemTooltip,
              icon: Icons.add_shopping_cart_outlined,
              onPressed: () => showAddReceiptItemSheet(context, ref),
            ),
            splitBaeAdaptiveToolbarIcon(
              context: context,
              tooltip: _settingsTooltip(l10n.settings),
              icon: Icons.settings_outlined,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ];

          final homeBody = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContent),
              child: Padding(
                padding: hinge,
                child: SplitHomeContent(
                  horizontalPadding: hPad,
                  onConfirmDeleteLine: confirmDeleteLine,
                  twoColumn: false,
                ),
              ),
            ),
          );

          if (hostPlatformIsApple()) {
            final theme = Theme.of(context);
            final bottomPad = MediaQuery.paddingOf(context).bottom;
            return CupertinoPageScaffold(
              backgroundColor: theme.colorScheme.surface,
              navigationBar: splitBaeCupertinoNavigationBar(
                context: context,
                title: l10n.appTitle,
                actions: narrowActions,
              ),
              child: Material(
                color: theme.colorScheme.surface,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    homeBody,
                    Positioned(
                      right: 16,
                      bottom: 16 + bottomPad,
                      child: _AppleAddPersonFab(
                        label: l10n.addPerson,
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await showAddParticipantSheet(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            appBar: splitBaeAdaptiveAppBar(
              context: context,
              title: l10n.appTitle,
              actions: narrowActions,
            ),
            body: homeBody,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await showAddParticipantSheet(context);
              },
              label: Text(l10n.addPerson),
              icon: const Icon(Icons.person_add),
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
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: Text(l10n.navHomeLabel),
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
                    ? Scaffold(
                        appBar: splitBaeAdaptiveAppBar(
                          context: context,
                          title: l10n.appTitle,
                          centerTitle: false,
                          actions: [
                            splitBaeAdaptiveToolbarIcon(
                              context: context,
                              tooltip: l10n.peopleTooltip,
                              icon: Icons.group_outlined,
                              onPressed: () =>
                                  showManageParticipantsSheet(context, ref),
                            ),
                            splitBaeAdaptiveToolbarIcon(
                              context: context,
                              tooltip: l10n.addItemTooltip,
                              icon: Icons.add_shopping_cart_outlined,
                              onPressed: () =>
                                  showAddReceiptItemSheet(context, ref),
                            ),
                          ],
                        ),
                        body: Padding(
                          padding: hinge,
                          child: SplitHomeContent(
                            horizontalPadding: hPad,
                            onConfirmDeleteLine: confirmDeleteLine,
                            twoColumn: twoPane,
                          ),
                        ),
                        floatingActionButton: FloatingActionButton.extended(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            await showAddParticipantSheet(context);
                          },
                          label: Text(l10n.addPerson),
                          icon: const Icon(Icons.person_add),
                        ),
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

String _settingsTooltip(String settingsLabel) {
  if (!isDesktopPlatform) return settingsLabel;
  final suffix = defaultTargetPlatform == TargetPlatform.macOS
      ? ' (⌘,)'
      : ' (Ctrl+,)';
  return '$settingsLabel$suffix';
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

/// Primary “add person” action on Apple narrow layout — Cupertino, not Material FAB.
class _AppleAddPersonFab extends StatelessWidget {
  const _AppleAddPersonFab({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.person_add_solid, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
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
