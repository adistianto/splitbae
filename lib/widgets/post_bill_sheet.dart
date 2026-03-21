import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/providers.dart';

Future<void> showPostBillSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _PostBillSheetBody(hostContext: context),
  );
}

class _PostBillSheetBody extends ConsumerStatefulWidget {
  const _PostBillSheetBody({required this.hostContext});

  /// Context under the page [Scaffold] (not the sheet route) for snackbars.
  final BuildContext hostContext;

  @override
  ConsumerState<_PostBillSheetBody> createState() => _PostBillSheetBodyState();
}

class _PostBillSheetBodyState extends ConsumerState<_PostBillSheetBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _errorMessage(Object e, AppLocalizations l10n) {
    if (e is StateError) {
      switch (e.message) {
        case 'empty_bill':
          return l10n.postBillErrorEmpty;
        case 'empty_participants':
          return l10n.postBillErrorNoParticipants;
        default:
          break;
      }
    }
    return e.toString();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(widget.hostContext);
    try {
      await ref.read(itemsProvider.notifier).postDraftBill(_controller.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.postBillSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_errorMessage(e, l10n))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.postBillTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.postBillSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.postBillDescriptionLabel,
              hintText: l10n.postBillDescriptionHint,
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
            onSubmitted: (_) => _submit(l10n),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => _submit(l10n),
            label: Text(l10n.postBillAction),
          ),
        ],
      ),
    );
  }
}
