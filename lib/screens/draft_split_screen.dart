import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/layout/adaptive_insets.dart';
import 'package:splitbae/core/layout/app_breakpoints.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/screens/balances_screen.dart';
import 'package:splitbae/screens/settings_screen.dart';
import 'package:splitbae/widgets/add_participant_sheet.dart';
import 'package:splitbae/widgets/add_receipt_item_sheet.dart';
import 'package:splitbae/widgets/confirm_delete_line.dart';
import 'package:splitbae/widgets/manage_participants_sheet.dart';
import 'package:splitbae/widgets/split_home_content.dart';
import 'package:splitbae/widgets/who_paid_sheet.dart';

/// Opens the draft split workspace (v0: full-screen flow from Bills, not a tab).
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
            icon: Icons.account_balance_wallet_outlined,
            onPressed: () => openBalancesScreen(context),
          ),
          splitBaeAdaptiveToolbarIcon(
            context: context,
            tooltip: l10n.peopleTooltip,
            icon: Icons.group_outlined,
            onPressed: () => showManageParticipantsSheet(context, ref),
          ),
          splitBaeAdaptiveToolbarIcon(
            context: context,
            tooltip: l10n.whoPaidTooltip,
            icon: Icons.payments_outlined,
            onPressed: () => showWhoPaidSheet(context, ref),
          ),
          splitBaeAdaptiveToolbarIcon(
            context: context,
            tooltip: l10n.addItemTooltip,
            icon: Icons.add_shopping_cart_outlined,
            onPressed: () => showAddReceiptItemSheet(context, ref),
          ),
          splitBaeAdaptiveToolbarIcon(
            context: context,
            tooltip: l10n.settings,
            icon: Icons.settings_outlined,
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
      body: SplitHomeContent(
        horizontalPadding: hPad,
        onConfirmDeleteLine: confirmDeleteLine,
        twoColumn: twoPane,
      ),
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
}
