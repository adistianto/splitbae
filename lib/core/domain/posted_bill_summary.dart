import '../database/app_database.dart';

/// Posted transaction row plus display fields for the Bills feed.
class PostedBillSummary {
  const PostedBillSummary({
    required this.transaction,
    required this.participantCount,
    required this.totalMinorPrimary,
    required this.participantIds,
    required this.lineLabelsSearchText,
  });

  final Transaction transaction;
  final int participantCount;

  /// Sum of line amounts in [transaction.currencyCode] (primary currency for this bill).
  final int totalMinorPrimary;

  /// Who was on this bill ([TransactionParticipants] at post time).
  final List<String> participantIds;

  /// Lowercased line labels joined for text search (v0: search items).
  final String lineLabelsSearchText;
}
