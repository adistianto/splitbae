import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/domain/participant_entry.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/src/rust/api/money.dart';
import 'package:splitbae/src/rust/api/receipt_split.dart';
import 'package:splitbae/src/rust/api/simple.dart';

/// Local tax/tip (minor units) for [Receipt] passed to [calculateSplit].
/// Line items and assignees remain the single source of truth in [itemsProvider].
@immutable
class DraftSplitAdjustments {
  const DraftSplitAdjustments({
    this.taxAmountMinor = 0,
    this.tipAmountMinor = 0,
  });

  final int taxAmountMinor;
  final int tipAmountMinor;

  DraftSplitAdjustments copyWith({int? taxAmountMinor, int? tipAmountMinor}) {
    return DraftSplitAdjustments(
      taxAmountMinor: taxAmountMinor ?? this.taxAmountMinor,
      tipAmountMinor: tipAmountMinor ?? this.tipAmountMinor,
    );
  }
}

/// Holds tax/tip and exposes mutations for the draft split workspace.
class DraftSplitNotifier extends Notifier<DraftSplitAdjustments> {
  @override
  DraftSplitAdjustments build() => const DraftSplitAdjustments();

  void setTaxAmountMinor(int minor) {
    final v = minor < 0 ? 0 : minor;
    state = state.copyWith(taxAmountMinor: v);
  }

  void setTipAmountMinor(int minor) {
    final v = minor < 0 ? 0 : minor;
    state = state.copyWith(tipAmountMinor: v);
  }

  Future<void> addReceiptItem(String name, double price, {int quantity = 1}) {
    return ref
        .read(itemsProvider.notifier)
        .addItem(name, price, quantity: quantity);
  }

  Future<void> removeReceiptItem(String lineId) {
    return ref.read(itemsProvider.notifier).deleteItem(lineId);
  }

  Future<void> updateReceiptItem({
    required String id,
    required String name,
    required double price,
    int quantity = 1,
  }) {
    return ref
        .read(itemsProvider.notifier)
        .updateItem(id: id, name: name, price: price, quantity: quantity);
  }

  /// Toggles [participantId] on [lineId], preserving empty-assignee = everyone semantics.
  Future<void> toggleAssigneeOnLine({
    required String lineId,
    required String participantId,
  }) async {
    final items = ref.read(itemsProvider);
    final i = items.indexWhere((e) => e.id == lineId);
    if (i < 0) return;
    final line = items[i];

    final active = await ref.read(draftBillActiveParticipantsProvider.future);
    if (active.isEmpty) return;

    final allIds = active.map((e) => e.id).toSet();
    var next = line.assignedParticipantIds.isEmpty
        ? {...allIds}
        : {...line.assignedParticipantIds};

    if (next.contains(participantId)) {
      next.remove(participantId);
    } else {
      next.add(participantId);
    }

    if (next.isEmpty ||
        (next.length == allIds.length && allIds.every(next.contains))) {
      await ref
          .read(itemsProvider.notifier)
          .setLineAssignments(lineId: lineId, selectedParticipantIds: {});
      return;
    }

    await ref
        .read(itemsProvider.notifier)
        .setLineAssignments(lineId: lineId, selectedParticipantIds: next);
  }
}

final draftSplitNotifierProvider =
    NotifierProvider<DraftSplitNotifier, DraftSplitAdjustments>(
      DraftSplitNotifier.new,
    );

int _expectedMinorScale(String currencyCode) {
  final c = currencyCode.trim().toUpperCase();
  if (c == 'IDR' || c == 'JPY' || c == 'KRW') return 0;
  return 2;
}

CurrencyAmount _currencyAmountFromMinor(int minor, String currencyCode) {
  final cc = currencyCode.trim().toUpperCase();
  return CurrencyAmount(
    amountMinor: PlatformInt64Util.from(minor),
    currencyCode: cc,
    scale: _expectedMinorScale(cc),
  );
}

/// Sorted lexicographic participant ids for “everyone on this bill”.
List<String> _sortedActiveIds(List<ParticipantEntry> active) {
  final ids = active.map((e) => e.id).toList();
  ids.sort();
  return ids;
}

List<String> _assigneeIdsForLine(
  LedgerLineItem line,
  List<ParticipantEntry> active,
) {
  final sorted = _sortedActiveIds(active);
  final activeSet = active.map((e) => e.id).toSet();
  if (line.assignedParticipantIds.isEmpty) {
    return sorted;
  }
  final filtered = line.assignedParticipantIds
      .where(activeSet.contains)
      .toList();
  if (filtered.isEmpty) {
    return sorted;
  }
  return filtered;
}

/// Same [Receipt] as [draftReceiptProvider], for posting flows that pass tax/tip explicitly
/// (e.g. add-transaction sheet tax field vs. draft split adjustments).
Receipt receiptForRustSplit({
  required List<LedgerLineItem> items,
  required List<ParticipantEntry> activeParticipants,
  required String currencyCode,
  required int taxAmountMinor,
  required int tipAmountMinor,
}) {
  final tax = _currencyAmountFromMinor(taxAmountMinor, currencyCode);
  final tip = _currencyAmountFromMinor(tipAmountMinor, currencyCode);
  final receiptItems = <ReceiptItem>[];
  for (final line in items) {
    final costMinor = amountToMinorUnits(
      amount: line.receiptItem.price,
      currencyCode: currencyCode,
    );
    final cc = currencyCode.trim().toUpperCase();
    receiptItems.add(
      ReceiptItem(
        name: line.receiptItem.name,
        cost: CurrencyAmount(
          amountMinor: costMinor,
          currencyCode: cc,
          scale: _expectedMinorScale(cc),
        ),
        assigneeIds: _assigneeIdsForLine(line, activeParticipants),
      ),
    );
  }
  return Receipt(items: receiptItems, tax: tax, tip: tip);
}

/// Live [Receipt] for Rust [calculateSplit], rebuilt when lines, participants, or tax/tip change.
final draftReceiptProvider = Provider<Receipt>((ref) {
  final items = ref.watch(itemsProvider);
  final adjustments = ref.watch(draftSplitNotifierProvider);
  final currency = ref.watch(draftBillCurrencyProvider);

  final active = ref
      .watch(draftBillActiveParticipantsProvider)
      .when(
        data: (v) => v,
        loading: () => ref.watch(participantsProvider),
        error: (_, _) => <ParticipantEntry>[],
      );

  return receiptForRustSplit(
    items: items,
    activeParticipants: active,
    currencyCode: currency,
    taxAmountMinor: adjustments.taxAmountMinor,
    tipAmountMinor: adjustments.tipAmountMinor,
  );
});

/// Real-time per-user totals from [calculateSplit] (items + proportional tax/tip).
final splitResultProvider = Provider<AsyncValue<List<UserOwedMinor>>>((ref) {
  final receipt = ref.watch(draftReceiptProvider);
  try {
    final out = calculateSplit(receipt: receipt);
    return AsyncValue.data(out);
  } catch (e, st) {
    return AsyncValue.error(e, st);
  }
});

/// Maps [UserOwedMinor.userId] to display names from current participants.
final draftSplitOwedDisplayNamesProvider = Provider<Map<String, String>>((ref) {
  final participants = ref.watch(participantsProvider);
  return {for (final p in participants) p.id: p.displayName};
});

/// Copies a posted bill into the draft, sets [editPostedTransactionIdProvider],
/// and hydrates tax/tip from the draft transaction row for the split workspace.
Future<void> beginEditPostedBill(
  WidgetRef ref,
  String postedTransactionId,
) async {
  await ref
      .read(itemsProvider.notifier)
      .copyPostedBillToDraft(postedTransactionId);
  ref.read(editPostedTransactionIdProvider.notifier).state =
      postedTransactionId;
  final db = ref.read(appDatabaseProvider);
  final draftTx = draftTransactionIdForLedger(kDefaultLedgerId);
  final row = await (db.select(
    db.transactions,
  )..where((t) => t.id.equals(draftTx))).getSingle();
  ref
      .read(draftSplitNotifierProvider.notifier)
      .setTaxAmountMinor(row.taxAmountMinor);
  ref
      .read(draftSplitNotifierProvider.notifier)
      .setTipAmountMinor(row.tipAmountMinor);
}
