import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/database/app_database.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';

/// Bills dashboard feed (v0 Bills / Transactions tab).
///
/// Wire-up slice: **dummy** [PostedBillSummary] rows; replace with DB-backed
/// [BillPostingRepository.listPostedBillSummaries] when persistence is ready.
/// Amounts are **minor units** only ([PostedBillSummary.totalMinorPrimary]).
final billsFeedProvider = Provider.autoDispose<List<PostedBillSummary>>((ref) {
  return _dummyPostedBillSummaries();
});

List<PostedBillSummary> _dummyPostedBillSummaries() {
  final now = DateTime.now();
  final ledgerId = kDefaultLedgerId;

  Transaction tx({
    required String id,
    required String description,
    required String category,
    required int createdAtMs,
    int taxAmountMinor = 0,
    String currencyCode = 'IDR',
    String kind = 'normal',
  }) {
    return Transaction(
      id: id,
      ledgerId: ledgerId,
      description: description,
      category: category,
      taxAmountMinor: taxAmountMinor,
      currencyCode: currencyCode,
      kind: kind,
      createdAtMs: createdAtMs,
      updatedAtMs: createdAtMs,
      receiptImagePath: null,
    );
  }

  final t1 = now.subtract(const Duration(days: 2)).millisecondsSinceEpoch;
  final t2 = now.subtract(const Duration(days: 5)).millisecondsSinceEpoch;
  final t3 = DateTime(now.year, now.month - 1, 18).millisecondsSinceEpoch;
  final t4 = DateTime(now.year, now.month - 1, 3).millisecondsSinceEpoch;
  final t5 = DateTime(now.year, now.month - 2, 22).millisecondsSinceEpoch;

  return [
    PostedBillSummary(
      transaction: tx(
        id: 'dummy-feed-001',
        description: 'Weekend brunch',
        category: 'food',
        createdAtMs: t1,
      ),
      participantCount: 3,
      totalMinorPrimary: 245_000,
      participantIds: const ['p_a', 'p_b', 'p_c'],
      lineLabelsSearchText: 'coffee avocado toast',
    ),
    PostedBillSummary(
      transaction: tx(
        id: 'dummy-feed-002',
        description: 'Airport transfer',
        category: 'transport',
        createdAtMs: t2,
      ),
      participantCount: 2,
      totalMinorPrimary: 185_000,
      participantIds: const ['p_a', 'p_b'],
      lineLabelsSearchText: 'taxi toll',
    ),
    PostedBillSummary(
      transaction: tx(
        id: 'dummy-feed-003',
        description: 'Concert tickets',
        category: 'entertainment',
        createdAtMs: t3,
      ),
      participantCount: 4,
      totalMinorPrimary: 1_200_000,
      participantIds: const ['p_a', 'p_b', 'p_c', 'p_d'],
      lineLabelsSearchText: 'vip seats',
    ),
    PostedBillSummary(
      transaction: tx(
        id: 'dummy-feed-004',
        description: 'Groceries',
        category: 'shopping',
        createdAtMs: t4,
      ),
      participantCount: 2,
      totalMinorPrimary: 412_500,
      participantIds: const ['p_a', 'p_b'],
      lineLabelsSearchText: 'milk bread',
    ),
    PostedBillSummary(
      transaction: tx(
        id: 'dummy-feed-005',
        description: 'Peer settlement',
        category: 'settlement',
        createdAtMs: t5,
      ),
      participantCount: 2,
      totalMinorPrimary: 50_000,
      participantIds: const ['p_a', 'p_b'],
      lineLabelsSearchText: 'settlement',
    ),
  ];
}
