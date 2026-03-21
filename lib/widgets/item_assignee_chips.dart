import 'package:flutter/material.dart';
import 'package:splitbae/core/domain/participant_entry.dart';
import 'package:splitbae/l10n/app_localizations.dart';

/// Toggle who shares a line item (equal split among selected people).
/// [assigneeIds] empty means **everyone** on the bill.
class ItemAssigneeChips extends StatelessWidget {
  const ItemAssigneeChips({
    super.key,
    required this.participants,
    required this.assigneeIds,
    required this.onAssigneesChanged,
    this.dense = false,
  });

  final List<ParticipantEntry> participants;
  final Set<String> assigneeIds;
  final ValueChanged<Set<String>> onAssigneesChanged;
  final bool dense;

  void _toggle(String participantId) {
    final all = participants.map((e) => e.id).toSet();
    var next = assigneeIds.isEmpty ? {...all} : {...assigneeIds};
    if (next.contains(participantId)) {
      next.remove(participantId);
    } else {
      next.add(participantId);
    }
    if (next.isEmpty || (next.length == all.length && all.every(next.contains))) {
      onAssigneesChanged({});
      return;
    }
    onAssigneesChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (participants.isEmpty) {
      return Text(
        l10n.itemAssigneesNeedPeople,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    final all = participants.map((e) => e.id).toSet();
    final effective = assigneeIds.isEmpty ? all : assigneeIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.itemAssigneesLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        SizedBox(height: dense ? 6 : 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in participants)
              FilterChip(
                label: Text(p.displayName),
                selected: effective.contains(p.id),
                onSelected: (_) => _toggle(p.id),
                showCheckmark: true,
              ),
          ],
        ),
      ],
    );
  }
}
