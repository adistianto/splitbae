import '../database/app_database.dart';

/// Posted transaction row plus display fields for the Bills feed.
class PostedBillSummary {
  const PostedBillSummary({
    required this.transaction,
    required this.participantCount,
    required this.totalMinorPrimary,
  });

  final Transaction transaction;
  final int participantCount;

  /// Sum of line amounts in [transaction.currencyCode] (primary currency for this bill).
  final int totalMinorPrimary;
}
