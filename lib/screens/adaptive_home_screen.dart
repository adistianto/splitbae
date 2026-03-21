import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/layout/app_breakpoints.dart';
import 'package:splitbae/core/platform/adaptive_confirm_dialog.dart';
import 'package:splitbae/core/platform/platform_capabilities.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/settings_screen.dart';
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

        final hPad = 16.0;

        if (!useRail) {
          final maxContent = wc == AppWindowClass.medium
              ? 720.0
              : double.infinity;
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.appTitle),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: l10n.peopleTooltip,
                  onPressed: () => showManageParticipantsSheet(context, ref),
                  icon: const Icon(Icons.group_outlined),
                ),
                IconButton(
                  tooltip: l10n.addItemTooltip,
                  onPressed: () => showAddReceiptItemSheet(context, ref),
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                ),
                IconButton(
                  tooltip: _settingsTooltip(l10n.settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            body: Center(
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
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await ref
                    .read(participantsProvider.notifier)
                    .addParticipant('New Friend');
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
                        appBar: AppBar(
                          title: Text(l10n.appTitle),
                          actions: [
                            IconButton(
                              tooltip: l10n.peopleTooltip,
                              onPressed: () =>
                                  showManageParticipantsSheet(context, ref),
                              icon: const Icon(Icons.group_outlined),
                            ),
                            IconButton(
                              tooltip: l10n.addItemTooltip,
                              onPressed: () =>
                                  showAddReceiptItemSheet(context, ref),
                              icon: const Icon(
                                Icons.add_shopping_cart_outlined,
                              ),
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
                            await ref
                                .read(participantsProvider.notifier)
                                .addParticipant('New Friend');
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
