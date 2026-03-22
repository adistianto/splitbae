import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/data/bill_posting_repository.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';
import 'package:splitbae/core/providers/database_providers.dart';

/// Bills dashboard feed: live [PostedBillSummary] rows from SQLite (newest first).
///
/// Backed by [BillPostingRepository.watchPostedBillSummaries]; amounts are **minor
/// units** only ([PostedBillSummary.totalMinorPrimary]).
final billsFeedProvider =
    StreamProvider.autoDispose<List<PostedBillSummary>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BillPostingRepository(db).watchPostedBillSummaries(kDefaultLedgerId);
});
