import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'currency_recording.dart';
import 'draft_bill_inclusion_repository.dart';
import 'participant_repository.dart';
import '../database/app_database.dart';
import '../domain/ledger_ids.dart';
import '../domain/ledger_line_item.dart';
import 'amount_minor.dart';
import '../../src/rust/api/simple.dart' show ReceiptItem;

class LineItemRepository {
  LineItemRepository(this._db);

  final AppDatabase _db;

  /// Lines for any transaction (draft or posted).
  Future<List<LedgerLineItem>> listLinesForTransaction({
    required String ledgerId,
    required String transactionId,
  }) async {
    final rows =
        await (_db.select(_db.receiptLines)
              ..where(
                (t) =>
                    t.ledgerId.equals(ledgerId) &
                    t.transactionId.equals(transactionId),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.createdAtMs)]))
            .get();
    final tpRows =
        await (_db.select(_db.transactionParticipants)
              ..where((x) => x.transactionId.equals(transactionId)))
            .get();
    var effective = tpRows.map((e) => e.participantId).toSet();
    if (effective.isEmpty) {
      final all = await ParticipantRepository(_db).listParticipants(ledgerId);
      effective = all.map((e) => e.id).toSet();
    }
    return await _mapRowsToLineItems(rows, effectiveParticipantIds: effective);
  }

  /// Lines for the ledger’s **draft** transaction (in-progress bill).
  Future<List<LedgerLineItem>> listLedgerLines(String ledgerId) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final rows =
        await (_db.select(_db.receiptLines)
              ..where(
                (t) =>
                    t.ledgerId.equals(ledgerId) &
                    t.transactionId.equals(draftTx),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.createdAtMs)]))
            .get();
    final all = await ParticipantRepository(_db).listParticipants(ledgerId);
    final effective = await DraftBillInclusionRepository(
      _db,
    ).effectiveIncludedIds(ledgerId, all);
    return await _mapRowsToLineItems(rows, effectiveParticipantIds: effective);
  }

  Future<List<LedgerLineItem>> _mapRowsToLineItems(
    List<ReceiptLine> rows, {
    required Set<String> effectiveParticipantIds,
  }) async {
    if (rows.isEmpty) return [];

    final lineIds = rows.map((r) => r.id).toList();
    final assigns =
        await (_db.select(_db.receiptLineAssignments)
              ..where((a) => a.lineId.isIn(lineIds)))
            .get();

    final byLine = <String, List<String>>{};
    for (final a in assigns) {
      byLine.putIfAbsent(a.lineId, () => []).add(a.participantId);
    }

    final effective = effectiveParticipantIds;
    return rows
        .map(
          (row) {
            final raw = byLine[row.id] ?? const [];
            final filtered =
                raw.where((id) => effective.contains(id)).toList();
            return LedgerLineItem(
              id: row.id,
              receiptItem: _toReceiptItem(row),
              quantity: row.quantity,
              assignedParticipantIds: filtered,
            );
          },
        )
        .toList();
  }

  /// ISO 4217 code on the draft [Transactions] row (bill-level recording currency).
  Future<String> getDraftTransactionCurrencyCode(String ledgerId) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final row = await (_db.select(_db.transactions)
          ..where((t) => t.id.equals(draftTx)))
        .getSingle();
    return row.currencyCode;
  }

  /// Returns the new line id. [currencyCode] is taken from the draft transaction
  /// (one currency per bill).
  Future<String> addLine({
    required String ledgerId,
    required String label,
    required double amount,
    int quantity = 1,
  }) async {
    final currencyCode = await getDraftTransactionCurrencyCode(ledgerId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final minor = amountToMinorUnits(amount, currencyCode);
    final q = quantity < 1 ? 1 : quantity;
    final id = const Uuid().v4();
    await _db
        .into(_db.receiptLines)
        .insert(
          ReceiptLinesCompanion.insert(
            id: id,
            ledgerId: ledgerId,
            transactionId: Value(draftTransactionIdForLedger(ledgerId)),
            label: label,
            amountMinor: minor,
            quantity: Value(q),
            currencyCode: currencyCode,
            createdAtMs: now,
            updatedAtMs: now,
          ),
        );
    return id;
  }

  Future<void> updateLine({
    required String id,
    required String label,
    required double amount,
    int quantity = 1,
  }) async {
    final row = await (_db.select(_db.receiptLines)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    final currencyCode =
        await getDraftTransactionCurrencyCode(row.ledgerId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final minor = amountToMinorUnits(amount, currencyCode);
    final q = quantity < 1 ? 1 : quantity;
    await (_db.update(_db.receiptLines)..where((t) => t.id.equals(id))).write(
      ReceiptLinesCompanion(
        label: Value(label),
        amountMinor: Value(minor),
        quantity: Value(q),
        currencyCode: Value(currencyCode),
        updatedAtMs: Value(now),
      ),
    );
  }

  Future<void> deleteLine(String id) async {
    await (_db.delete(_db.receiptLines)..where((t) => t.id.equals(id))).go();
  }

  /// Keeps the draft [Transactions] row’s [currencyCode] as the single **bill**
  /// currency. When there are no lines, uses [defaultWhenNoLines]. When lines
  /// exist, uses the dominant code among lines, then **normalizes** every line
  /// to that code (amount minors unchanged — same as a relabel for MVP).
  Future<void> syncDraftTransactionRecordingCurrency({
    required String ledgerId,
    required String defaultWhenNoLines,
  }) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final rows =
        await (_db.select(_db.receiptLines)
              ..where(
                (t) =>
                    t.ledgerId.equals(ledgerId) &
                    t.transactionId.equals(draftTx),
              ))
            .get();
    final String code;
    if (rows.isEmpty) {
      code = defaultWhenNoLines;
    } else {
      final totals = <String, int>{};
      for (final r in rows) {
        totals[r.currencyCode] =
            (totals[r.currencyCode] ?? 0) + r.amountMinor.abs();
      }
      code = pickDominantCurrencyCode(
        totals,
        fallbackWhenEmpty: defaultWhenNoLines,
      );
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.transactions)..where((t) => t.id.equals(draftTx)))
        .write(
      TransactionsCompanion(
        currencyCode: Value(code),
        updatedAtMs: Value(now),
      ),
    );
    if (rows.isNotEmpty) {
      await (_db.update(_db.receiptLines)
            ..where((t) => t.ledgerId.equals(ledgerId))
            ..where((t) => t.transactionId.equals(draftTx)))
          .write(
        ReceiptLinesCompanion(
          currencyCode: Value(code),
          updatedAtMs: Value(now),
        ),
      );
    }
  }

  /// Persists who shares this line. Empty selection or “everyone” clears rows
  /// (meaning split with all participants).
  Future<void> replaceLineAssignments({
    required String lineId,
    required Set<String> selectedParticipantIds,
    required Set<String> allParticipantIds,
  }) async {
    final all = allParticipantIds;
    if (all.isEmpty) {
      await (_db.delete(_db.receiptLineAssignments)
            ..where((a) => a.lineId.equals(lineId)))
          .go();
      return;
    }

    final sel = selectedParticipantIds.where(all.contains).toSet();
    final isEveryone =
        sel.length == all.length && sel.containsAll(all);

    await _db.transaction(() async {
      await (_db.delete(_db.receiptLineAssignments)
            ..where((a) => a.lineId.equals(lineId)))
          .go();
      if (isEveryone || sel.isEmpty) {
        return;
      }
      for (final pid in sel) {
        await _db.into(_db.receiptLineAssignments).insert(
              ReceiptLineAssignmentsCompanion.insert(
                lineId: lineId,
                participantId: pid,
              ),
            );
      }
    });
  }

  ReceiptItem _toReceiptItem(ReceiptLine row) {
    return ReceiptItem(
      name: row.label,
      price: minorUnitsToAmount(row.amountMinor, row.currencyCode),
      currencyCode: row.currencyCode,
    );
  }
}
