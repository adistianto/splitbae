import 'package:splitbae/src/rust/api/simple.dart' show ReceiptItem;

/// Stable row id + FRB payload for split math + optional assignees.
class LedgerLineItem {
  const LedgerLineItem({
    required this.id,
    required this.receiptItem,
    this.assignedParticipantIds = const [],
  });

  final String id;
  final ReceiptItem receiptItem;

  /// Explicit assignees for this line (equal split of the line amount among them).
  /// **Empty** means “all current participants” (same as equal split across the group).
  final List<String> assignedParticipantIds;
}
