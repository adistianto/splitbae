import 'package:splitbae/src/rust/api/simple.dart' show DraftLineItem;

/// Stable row id + FRB payload for split math + optional assignees.
class LedgerLineItem {
  const LedgerLineItem({
    required this.id,
    required this.receiptItem,
    this.quantity = 1,
    this.assignedParticipantIds = const [],
  });

  final String id;
  final DraftLineItem receiptItem;

  /// Quantity for this receipt row (≥ 1). [price] on [receiptItem] is the **line total**.
  final int quantity;

  /// Line total ÷ quantity when quantity is positive.
  double get unitPrice =>
      quantity > 0 ? receiptItem.price / quantity : receiptItem.price;

  /// Explicit assignees for this line (equal split of the line amount among them).
  /// **Empty** means “all current participants” (same as equal split across the group).
  final List<String> assignedParticipantIds;
}
