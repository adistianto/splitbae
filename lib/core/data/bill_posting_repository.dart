import 'package:drift/drift.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:uuid/uuid.dart';

import 'currency_recording.dart';
import 'receipt_image_store.dart';
import '../database/app_database.dart';
import '../domain/ledger_ids.dart';
import '../domain/ledger_line_item.dart';
import '../domain/posted_bill_summary.dart';
import 'amount_minor.dart';
import 'draft_bill_inclusion_repository.dart';
import 'draft_payment_repository.dart';
import 'line_item_repository.dart';
import 'participant_repository.dart';
import '../../src/rust/api/receipt_split.dart' show ReceiptItem, UserOwedMinor;
import '../../src/rust/api/simple.dart' as rust;

int _minorPlatformToInt(PlatformInt64 m) => m.toInt();

Map<String, int> _sumOwedByCurrency(List<UserOwedMinor> rows) {
  final out = <String, int>{};
  for (final o in rows) {
    final c = o.currencyCode.trim().toUpperCase();
    if (c.isEmpty) continue;
    out[c] = (out[c] ?? 0) + _minorPlatformToInt(o.amountMinor);
  }
  return out;
}

/// Moves the in-progress draft bill into a new [Transaction] row (history) and
/// leaves the draft empty for the next bill.
class BillPostingRepository {
  BillPostingRepository(this._db);

  final AppDatabase _db;

  /// Emits whenever any [Transactions] row for [ledgerId] changes (post, delete, etc.).
  Stream<List<PostedBillSummary>> watchPostedBillSummaries(String ledgerId) {
    return (_db.select(_db.transactions)
          ..where((t) => t.ledgerId.equals(ledgerId)))
        .watch()
        .asyncMap((_) => listPostedBillSummaries(ledgerId));
  }

  /// Posted bills with participant counts and primary-currency totals for the feed.
  Future<List<PostedBillSummary>> listPostedBillSummaries(
    String ledgerId,
  ) async {
    final txs = await listPostedTransactions(ledgerId);
    final lineRepo = LineItemRepository(_db);
    final out = <PostedBillSummary>[];
    for (final t in txs) {
      final participants = await (_db.select(
        _db.transactionParticipants,
      )..where((x) => x.transactionId.equals(t.id))).get();
      final lines = await lineRepo.listLinesForTransaction(
        ledgerId: ledgerId,
        transactionId: t.id,
      );
      var sumPrimary = 0;
      final labelParts = <String>[];
      for (final line in lines) {
        labelParts.add(line.receiptItem.name);
        if (line.receiptItem.currencyCode == t.currencyCode) {
          sumPrimary += amountToMinorUnits(
            line.receiptItem.price,
            line.receiptItem.currencyCode,
          );
        }
      }
      final pIds = participants.map((e) => e.participantId).toList();
      final searchBlob = labelParts.join(' ').toLowerCase();
      out.add(
        PostedBillSummary(
          transaction: t,
          participantCount: participants.length,
          totalMinorPrimary: sumPrimary,
          participantIds: pIds,
          lineLabelsSearchText: searchBlob,
        ),
      );
    }
    return out;
  }

  /// Posted transactions for the ledger, newest first (excludes the draft row).
  Future<List<Transaction>> listPostedTransactions(String ledgerId) async {
    final draftId = draftTransactionIdForLedger(ledgerId);
    final rows =
        await (_db.select(_db.transactions)
              ..where((t) => t.ledgerId.equals(ledgerId))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.createdAtMs,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return rows.where((r) => r.id != draftId).toList();
  }

  /// Persists the current draft as a completed expense and clears the draft.
  ///
  /// [splitOwedMinor] must be the exact Rust [calculate_split] output for this bill
  /// (no Dart-side split math). [taxAmountMinor] and [tipAmountMinor] are persisted
  /// on the transaction row as recorded.
  ///
  /// Throws if there are no lines, no participants, [splitOwedMinor] is empty, or
  /// payments do not match the Rust bill total per currency.
  Future<void> postDraftBill({
    required String ledgerId,
    required String description,
    required List<UserOwedMinor> splitOwedMinor,
    required int taxAmountMinor,
    required int tipAmountMinor,
    String category = 'other',
    int? createdAtMs,
    String? receiptSourcePath,
  }) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final lines = await LineItemRepository(_db).listLedgerLines(ledgerId);
    if (lines.isEmpty) {
      throw StateError('empty_bill');
    }

    final participants = await ParticipantRepository(
      _db,
    ).listParticipants(ledgerId);
    if (participants.isEmpty) {
      throw StateError('empty_participants');
    }

    final inclusionRepo = DraftBillInclusionRepository(_db);
    final includedIds = await inclusionRepo.effectiveIncludedIds(
      ledgerId,
      participants,
    );
    if (includedIds.isEmpty) {
      throw StateError('empty_participants');
    }

    if (splitOwedMinor.isEmpty) {
      throw StateError('split_incomplete');
    }

    final draftPay = DraftPaymentRepository(_db);
    await draftPay.pruneExcludedDraftPayments(ledgerId, includedIds);
    var paymentRows = await draftPay.listForDraft(ledgerId);

    final totals = await draftPay.draftLineTotalsByCurrency(ledgerId);
    final owedByCcy = _sumOwedByCurrency(splitOwedMinor);

    final lineTotalsForValidate = <rust.LineTotalMinor>[];
    for (final e in owedByCcy.entries) {
      if (e.value > 0) {
        lineTotalsForValidate.add(
          rust.LineTotalMinor(
            currencyCode: e.key,
            amountMinor: PlatformInt64Util.from(e.value),
          ),
        );
      }
    }

    final paymentsForValidate = <rust.DraftPaymentMinor>[];
    final payerId = participants
        .firstWhere((p) => includedIds.contains(p.id))
        .id;
    if (paymentRows.isEmpty) {
      for (final e in totals.entries) {
        if (e.value <= 0) continue;
        paymentsForValidate.add(
          rust.DraftPaymentMinor(
            participantId: payerId,
            currencyCode: e.key,
            amountMinor: PlatformInt64Util.from(e.value),
          ),
        );
      }
    } else {
      for (final r in paymentRows) {
        if (r.amountMinor == 0) continue;
        if (!includedIds.contains(r.participantId)) continue;
        paymentsForValidate.add(
          rust.DraftPaymentMinor(
            participantId: r.participantId,
            currencyCode: r.currencyCode,
            amountMinor: PlatformInt64Util.from(r.amountMinor),
          ),
        );
      }
    }

    try {
      rust.validateBillPaymentsSum(
        lineTotalsMinor: lineTotalsForValidate,
        payments: paymentsForValidate,
      );
    } catch (_) {
      await draftPay.syncAfterInclusionChange(ledgerId, includedIds);
      paymentRows = await draftPay.listForDraft(ledgerId);
      paymentsForValidate.clear();
      if (paymentRows.isEmpty) {
        for (final e in totals.entries) {
          if (e.value <= 0) continue;
          paymentsForValidate.add(
            rust.DraftPaymentMinor(
              participantId: payerId,
              currencyCode: e.key,
              amountMinor: PlatformInt64Util.from(e.value),
            ),
          );
        }
      } else {
        for (final r in paymentRows) {
          if (r.amountMinor == 0) continue;
          paymentsForValidate.add(
            rust.DraftPaymentMinor(
              participantId: r.participantId,
              currencyCode: r.currencyCode,
              amountMinor: PlatformInt64Util.from(r.amountMinor),
            ),
          );
        }
      }
      rust.validateBillPaymentsSum(
        lineTotalsMinor: lineTotalsForValidate,
        payments: paymentsForValidate,
      );
    }

    final primaryCcy = pickDominantCurrencyCode(
      owedByCcy,
      fallbackWhenEmpty: _fallbackCurrencyFromLines(lines),
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final postedId = const Uuid().v4();
    final atMs = createdAtMs ?? now;
    final persistedReceipt = await persistReceiptImageFromPath(
      receiptSourcePath,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: postedId,
              ledgerId: ledgerId,
              description: Value(description.trim()),
              category: Value(category),
              taxAmountMinor: Value(taxAmountMinor),
              tipAmountMinor: Value(tipAmountMinor),
              currencyCode: Value(primaryCcy),
              kind: const Value('normal'),
              createdAtMs: atMs,
              updatedAtMs: now,
              receiptImagePath: Value(persistedReceipt),
            ),
          );

      for (final p in participants) {
        if (!includedIds.contains(p.id)) continue;
        await _db
            .into(_db.transactionParticipants)
            .insert(
              TransactionParticipantsCompanion.insert(
                transactionId: postedId,
                participantId: p.id,
              ),
            );
      }

      for (final o in splitOwedMinor) {
        final ccy = o.currencyCode.trim().toUpperCase();
        await _db
            .into(_db.transactionSplitObligations)
            .insert(
              TransactionSplitObligationsCompanion.insert(
                transactionId: postedId,
                participantId: o.userId,
                amountMinor: _minorPlatformToInt(o.amountMinor),
                currencyCode: ccy,
              ),
            );
      }

      await (_db.update(_db.receiptLines)
            ..where((t) => t.ledgerId.equals(ledgerId))
            ..where((t) => t.transactionId.equals(draftTx)))
          .write(ReceiptLinesCompanion(transactionId: Value(postedId)));

      await (_db.update(_db.transactionPayments)
            ..where((t) => t.transactionId.equals(draftTx)))
          .write(TransactionPaymentsCompanion(transactionId: Value(postedId)));

      await (_db.update(_db.transactions)..where((t) => t.id.equals(draftTx)))
          .write(TransactionsCompanion(updatedAtMs: Value(now)));
    });
  }

  /// Replaces an existing posted bill with the current **draft** snapshot (lines,
  /// payments, inclusion) and Rust split output. Updates [postedTransactionId] in
  /// place so the ledger [Transactions] watch emits for the dashboard.
  ///
  /// [receiptItems] must match the [Receipt] used to produce [splitOwedMinor]
  /// (same line count/order as draft lines in the DB).
  Future<void> updatePostedBill({
    required String ledgerId,
    required String postedTransactionId,
    required String description,
    required List<ReceiptItem> receiptItems,
    required List<UserOwedMinor> splitOwedMinor,
    required int taxAmountMinor,
    required int tipAmountMinor,
    String category = 'other',
  }) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    if (postedTransactionId == draftTx) {
      throw StateError('cannot_edit_draft');
    }

    final postedRow = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(postedTransactionId))).getSingleOrNull();
    if (postedRow == null || postedRow.ledgerId != ledgerId) {
      throw StateError('missing_transaction');
    }
    if (postedRow.kind != 'normal') {
      throw StateError('not_splittable_transaction');
    }

    final lines = await LineItemRepository(_db).listLedgerLines(ledgerId);
    if (lines.isEmpty) {
      throw StateError('empty_bill');
    }
    if (receiptItems.length != lines.length) {
      throw StateError('receipt_mismatch');
    }

    final participants = await ParticipantRepository(
      _db,
    ).listParticipants(ledgerId);
    if (participants.isEmpty) {
      throw StateError('empty_participants');
    }

    final inclusionRepo = DraftBillInclusionRepository(_db);
    final includedIds = await inclusionRepo.effectiveIncludedIds(
      ledgerId,
      participants,
    );
    if (includedIds.isEmpty) {
      throw StateError('empty_participants');
    }

    if (splitOwedMinor.isEmpty) {
      throw StateError('split_incomplete');
    }

    final draftPay = DraftPaymentRepository(_db);
    await draftPay.pruneExcludedDraftPayments(ledgerId, includedIds);
    var paymentRows = await draftPay.listForDraft(ledgerId);

    final totals = await draftPay.draftLineTotalsByCurrency(ledgerId);
    final owedByCcy = _sumOwedByCurrency(splitOwedMinor);

    final lineTotalsForValidate = <rust.LineTotalMinor>[];
    for (final e in owedByCcy.entries) {
      if (e.value > 0) {
        lineTotalsForValidate.add(
          rust.LineTotalMinor(
            currencyCode: e.key,
            amountMinor: PlatformInt64Util.from(e.value),
          ),
        );
      }
    }

    final paymentsForValidate = <rust.DraftPaymentMinor>[];
    final payerId = participants
        .firstWhere((p) => includedIds.contains(p.id))
        .id;
    if (paymentRows.isEmpty) {
      for (final e in totals.entries) {
        if (e.value <= 0) continue;
        paymentsForValidate.add(
          rust.DraftPaymentMinor(
            participantId: payerId,
            currencyCode: e.key,
            amountMinor: PlatformInt64Util.from(e.value),
          ),
        );
      }
    } else {
      for (final r in paymentRows) {
        if (r.amountMinor == 0) continue;
        if (!includedIds.contains(r.participantId)) continue;
        paymentsForValidate.add(
          rust.DraftPaymentMinor(
            participantId: r.participantId,
            currencyCode: r.currencyCode,
            amountMinor: PlatformInt64Util.from(r.amountMinor),
          ),
        );
      }
    }

    try {
      rust.validateBillPaymentsSum(
        lineTotalsMinor: lineTotalsForValidate,
        payments: paymentsForValidate,
      );
    } catch (_) {
      await draftPay.syncAfterInclusionChange(ledgerId, includedIds);
      paymentRows = await draftPay.listForDraft(ledgerId);
      paymentsForValidate.clear();
      if (paymentRows.isEmpty) {
        for (final e in totals.entries) {
          if (e.value <= 0) continue;
          paymentsForValidate.add(
            rust.DraftPaymentMinor(
              participantId: payerId,
              currencyCode: e.key,
              amountMinor: PlatformInt64Util.from(e.value),
            ),
          );
        }
      } else {
        for (final r in paymentRows) {
          if (r.amountMinor == 0) continue;
          paymentsForValidate.add(
            rust.DraftPaymentMinor(
              participantId: r.participantId,
              currencyCode: r.currencyCode,
              amountMinor: PlatformInt64Util.from(r.amountMinor),
            ),
          );
        }
      }
      rust.validateBillPaymentsSum(
        lineTotalsMinor: lineTotalsForValidate,
        payments: paymentsForValidate,
      );
    }

    final primaryCcy = pickDominantCurrencyCode(
      owedByCcy,
      fallbackWhenEmpty: _fallbackCurrencyFromLines(lines),
    );
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await (_db.delete(
        _db.transactionSplitObligations,
      )..where((t) => t.transactionId.equals(postedTransactionId))).go();
      await (_db.delete(
        _db.transactionParticipants,
      )..where((t) => t.transactionId.equals(postedTransactionId))).go();
      await (_db.delete(
        _db.receiptLines,
      )..where((t) => t.transactionId.equals(postedTransactionId))).go();
      await (_db.delete(
        _db.transactionPayments,
      )..where((t) => t.transactionId.equals(postedTransactionId))).go();

      await (_db.update(_db.receiptLines)
            ..where((t) => t.ledgerId.equals(ledgerId))
            ..where((t) => t.transactionId.equals(draftTx)))
          .write(
            ReceiptLinesCompanion(transactionId: Value(postedTransactionId)),
          );

      await (_db.update(
        _db.transactionPayments,
      )..where((t) => t.transactionId.equals(draftTx))).write(
        TransactionPaymentsCompanion(transactionId: Value(postedTransactionId)),
      );

      for (final p in participants) {
        if (!includedIds.contains(p.id)) continue;
        await _db
            .into(_db.transactionParticipants)
            .insert(
              TransactionParticipantsCompanion.insert(
                transactionId: postedTransactionId,
                participantId: p.id,
              ),
            );
      }

      for (final o in splitOwedMinor) {
        final ccy = o.currencyCode.trim().toUpperCase();
        await _db
            .into(_db.transactionSplitObligations)
            .insert(
              TransactionSplitObligationsCompanion.insert(
                transactionId: postedTransactionId,
                participantId: o.userId,
                amountMinor: _minorPlatformToInt(o.amountMinor),
                currencyCode: ccy,
              ),
            );
      }

      await (_db.update(
        _db.transactions,
      )..where((t) => t.id.equals(postedTransactionId))).write(
        TransactionsCompanion(
          description: Value(description.trim()),
          category: Value(category),
          taxAmountMinor: Value(taxAmountMinor),
          tipAmountMinor: Value(tipAmountMinor),
          currencyCode: Value(primaryCcy),
          updatedAtMs: Value(now),
        ),
      );

      await (_db.update(_db.transactions)..where((t) => t.id.equals(draftTx)))
          .write(TransactionsCompanion(updatedAtMs: Value(now)));
    });
  }

  String _fallbackCurrencyFromLines(List<LedgerLineItem> lines) {
    if (lines.isEmpty) return 'IDR';
    return lines.first.receiptItem.currencyCode;
  }

  /// Copies a **posted** bill into the ledger’s **draft** row (replacing any
  /// in-progress draft). Receipt image is re-copied into app documents so the
  /// draft is independent of the posted row’s file lifecycle.
  ///
  /// Restores line assignments, “who’s splitting”, and payment rows from the
  /// posted transaction. Throws if the bill has no lines or no participants.
  Future<void> copyPostedTransactionToDraft({
    required String ledgerId,
    required String postedTransactionId,
  }) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    if (postedTransactionId == draftTx) {
      throw StateError('cannot_copy_draft');
    }

    final posted = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(postedTransactionId))).getSingleOrNull();
    if (posted == null || posted.ledgerId != ledgerId) {
      throw StateError('missing_transaction');
    }
    if (posted.kind != 'normal') {
      throw StateError('not_splittable_transaction');
    }

    final tpRows = await (_db.select(
      _db.transactionParticipants,
    )..where((x) => x.transactionId.equals(postedTransactionId))).get();
    final postedParticipantIds = tpRows.map((e) => e.participantId).toSet();
    if (postedParticipantIds.isEmpty) {
      throw StateError('no_participants');
    }

    final lineRows =
        await (_db.select(_db.receiptLines)
              ..where((t) => t.ledgerId.equals(ledgerId))
              ..where((t) => t.transactionId.equals(postedTransactionId))
              ..orderBy([(t) => OrderingTerm(expression: t.createdAtMs)]))
            .get();
    if (lineRows.isEmpty) {
      throw StateError('no_lines');
    }

    final paymentRows = await (_db.select(
      _db.transactionPayments,
    )..where((t) => t.transactionId.equals(postedTransactionId))).get();

    final persistedReceipt = await persistReceiptImageFromPath(
      posted.receiptImagePath,
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final uuid = const Uuid();

    await _db.transaction(() async {
      await (_db.delete(_db.receiptLines)
            ..where((t) => t.ledgerId.equals(ledgerId))
            ..where((t) => t.transactionId.equals(draftTx)))
          .go();

      await (_db.delete(
        _db.transactionPayments,
      )..where((t) => t.transactionId.equals(draftTx))).go();

      await (_db.update(
        _db.transactions,
      )..where((t) => t.id.equals(draftTx))).write(
        TransactionsCompanion(
          description: Value(posted.description),
          category: Value(posted.category),
          taxAmountMinor: Value(posted.taxAmountMinor),
          tipAmountMinor: Value(posted.tipAmountMinor),
          currencyCode: Value(posted.currencyCode),
          receiptImagePath: Value(persistedReceipt),
          updatedAtMs: Value(now),
        ),
      );

      final lineIdMap = <String, String>{};
      for (final r in lineRows) {
        final newId = uuid.v4();
        lineIdMap[r.id] = newId;
        await _db
            .into(_db.receiptLines)
            .insert(
              ReceiptLinesCompanion.insert(
                id: newId,
                ledgerId: ledgerId,
                transactionId: Value(draftTx),
                label: r.label,
                amountMinor: r.amountMinor,
                quantity: Value(r.quantity),
                currencyCode: r.currencyCode,
                createdAtMs: now,
                updatedAtMs: now,
              ),
            );
      }

      final oldLineIds = lineRows.map((e) => e.id).toList();
      final assigns = await (_db.select(
        _db.receiptLineAssignments,
      )..where((a) => a.lineId.isIn(oldLineIds))).get();

      for (final a in assigns) {
        final newLineId = lineIdMap[a.lineId];
        if (newLineId == null) continue;
        await _db
            .into(_db.receiptLineAssignments)
            .insert(
              ReceiptLineAssignmentsCompanion.insert(
                lineId: newLineId,
                participantId: a.participantId,
              ),
            );
      }
    });

    await DraftBillInclusionRepository(
      _db,
    ).setIncludedParticipants(ledgerId, postedParticipantIds);

    final rebuilt = <TransactionPayment>[];
    for (final p in paymentRows) {
      rebuilt.add(
        TransactionPayment(
          id: uuid.v4(),
          transactionId: draftTx,
          participantId: p.participantId,
          amountMinor: p.amountMinor,
          currencyCode: p.currencyCode,
        ),
      );
    }
    await DraftPaymentRepository(
      _db,
    ).replaceDraftPayments(ledgerId: ledgerId, rows: rebuilt);

    await LineItemRepository(_db).syncDraftTransactionRecordingCurrency(
      ledgerId: ledgerId,
      defaultWhenNoLines: posted.currencyCode,
    );
  }

  /// Removes a posted transaction and dependent rows; deletes receipt file if any.
  Future<void> deletePostedTransaction(String transactionId) async {
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (row == null) return;
    await deleteReceiptImageFileIfExists(row.receiptImagePath);
    await (_db.delete(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).go();
  }
}
