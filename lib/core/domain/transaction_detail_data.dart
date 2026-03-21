import '../database/app_database.dart';
import 'ledger_line_item.dart';

/// Read model for the posted bill detail screen.
class TransactionDetailData {
  const TransactionDetailData({
    required this.transaction,
    required this.lines,
    required this.payments,
    required this.participantNames,
    required this.participantCount,
  });

  final Transaction transaction;
  final List<LedgerLineItem> lines;
  final List<TransactionPayment> payments;

  /// Ledger participant id → display name.
  final Map<String, String> participantNames;

  /// Snapshot count from [TransactionParticipants] at post time.
  final int participantCount;
}
