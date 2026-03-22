import 'package:flutter/material.dart';
import 'package:splitbae/core/domain/participant_entry.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
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
    this.avatarOnly = false,
    this.showMainLabel = true,
    this.caption,
  });

  final List<ParticipantEntry> participants;
  final Set<String> assigneeIds;
  final ValueChanged<Set<String>> onAssigneesChanged;
  final bool dense;

  /// v0-style small initials only (add-expense-sheet item row).
  final bool avatarOnly;

  /// When false, hides the "Split with" heading (caption may still show).
  final bool showMainLabel;

  /// Optional line under the heading (e.g. Shared by all / Assigned to n).
  final String? caption;

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
    final cs = Theme.of(context).colorScheme;

    if (avatarOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caption != null) ...[
            Text(
              caption!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: dense ? 6 : 8),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in participants)
                _V0AssigneeDot(
                  initial: splitBaeInitialGrapheme(p.displayName),
                  selected: effective.contains(p.id),
                  sharedByAll: assigneeIds.isEmpty,
                  onTap: () => _toggle(p.id),
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMainLabel)
          Text(
            l10n.itemAssigneesLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        if (showMainLabel) SizedBox(height: dense ? 6 : 8),
        if (caption != null) ...[
          Text(
            caption!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          SizedBox(height: dense ? 6 : 8),
        ],
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

class _V0AssigneeDot extends StatelessWidget {
  const _V0AssigneeDot({
    required this.initial,
    required this.selected,
    required this.sharedByAll,
    required this.onTap,
  });

  final String initial;
  final bool selected;
  final bool sharedByAll;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? cs.primary
                : sharedByAll
                    ? cs.primary.withValues(alpha: 0.2)
                    : cs.onSurfaceVariant.withValues(alpha: 0.15),
            border: sharedByAll && selected
                ? Border.all(color: cs.primary.withValues(alpha: 0.35))
                : (!selected && !sharedByAll)
                    ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.4))
                    : null,
          ),
          child: Text(
            initial,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}
