import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';
import 'package:splitbae/features/bills/application/bills_provider.dart';
import 'package:splitbae/providers.dart' show participantsProvider;

/// Single-category filter for the Transactions ledger tab.
enum LedgerCategoryFilter {
  all,
  food,
  transport,
  accommodation,
  entertainment,
  shopping,
  utilities,
  settlement,
  other,
}

extension LedgerCategoryFilterX on LedgerCategoryFilter {
  /// v0 category id stored on [Transactions.category].
  String get id {
    return switch (this) {
      LedgerCategoryFilter.all => 'all',
      LedgerCategoryFilter.food => 'food',
      LedgerCategoryFilter.transport => 'transport',
      LedgerCategoryFilter.accommodation => 'accommodation',
      LedgerCategoryFilter.entertainment => 'entertainment',
      LedgerCategoryFilter.shopping => 'shopping',
      LedgerCategoryFilter.utilities => 'utilities',
      LedgerCategoryFilter.settlement => 'settlement',
      LedgerCategoryFilter.other => 'other',
    };
  }
}

/// Query string used by the dense Transactions ledger list.
final ledgerSearchQueryProvider = StateProvider<String>((ref) => '');

/// Selected category for the Transactions ledger list.
final ledgerCategoryFilterProvider =
    StateProvider<LedgerCategoryFilter>((ref) => LedgerCategoryFilter.all);

/// Bills feed (posted transactions) filtered by:
/// - [ledgerSearchQueryProvider]: matches bill description OR participant names
/// - [ledgerCategoryFilterProvider]: matches [Transaction.category]
final filteredTransactionsProvider =
    Provider.autoDispose<AsyncValue<List<PostedBillSummary>>>((ref) {
  final feedAsync = ref.watch(billsFeedProvider);
  final query = ref.watch(ledgerSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(ledgerCategoryFilterProvider);
  final participants = ref.watch(participantsProvider);

  return feedAsync.when(
    data: (all) {
      final scopedByCategory = category == LedgerCategoryFilter.all
          ? all
          : all.where((s) => s.transaction.category == category.id).toList();

      if (query.isEmpty) {
        return AsyncValue.data(scopedByCategory);
      }

      final nameById = <String, String>{
        for (final p in participants) p.id: p.displayName.toLowerCase(),
      };

      final filtered = scopedByCategory.where((s) {
        final descHit = s.transaction.description.toLowerCase().contains(query);
        if (descHit) return true;

        for (final pid in s.participantIds) {
          final n = nameById[pid];
          if (n != null && n.contains(query)) return true;

          // If participants aren’t loaded yet (or id not present), fall back
          // to matching the raw participant id.
          if (pid.toLowerCase().contains(query)) return true;
        }
        return false;
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

