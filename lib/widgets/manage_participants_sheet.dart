import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/domain/participant_entry.dart';
import 'package:splitbae/providers.dart';

Future<void> showManageParticipantsSheet(
  BuildContext context,
  WidgetRef ref,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Consumer(
            builder: (context, r, _) {
              final l10n = AppLocalizations.of(context)!;
              final entries = r.watch(participantsProvider);
              final maxH = MediaQuery.sizeOf(context).height * 0.45;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Text(
                      l10n.managePeopleTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  SizedBox(
                    height: maxH,
                    child: ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return ListTile(
                          title: Text(e.displayName),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.renameParticipantAction,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showRenameDialog(
                                  context,
                                  r,
                                  e,
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.deleteAction,
                                icon: const Icon(Icons.person_remove_outlined),
                                onPressed: () => _confirmRemove(
                                  context,
                                  r,
                                  e,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

Future<void> _showRenameDialog(
  BuildContext context,
  WidgetRef ref,
  ParticipantEntry entry,
) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: entry.displayName);
  try {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameParticipantTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.participantDisplayNameLabel,
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final name = controller.text.trim();
      if (name.isNotEmpty) {
        await ref.read(participantsProvider.notifier).renameParticipant(
              id: entry.id,
              displayName: name,
            );
      }
    }
  } finally {
    controller.dispose();
  }
}

Future<void> _confirmRemove(
  BuildContext context,
  WidgetRef ref,
  ParticipantEntry entry,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.removeParticipantTitle),
      content: Text(l10n.removeParticipantBody(entry.displayName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.deleteAction),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(participantsProvider.notifier).removeParticipant(entry.id);
  }
}
