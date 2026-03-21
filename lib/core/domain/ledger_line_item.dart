import 'package:splitbae/src/rust/api/simple.dart' show ReceiptItem;

/// Stable row id + FRB payload for split math.
class LedgerLineItem {
  const LedgerLineItem({required this.id, required this.receiptItem});

  final String id;
  final ReceiptItem receiptItem;
}
