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
import '../../src/rust/api/simple.dart' as rust;

/// Moves the in-progress draft bill into a new [Transaction] row (history) and
/// leaves the draft empty for the next bill.
class BillPostingRepository {
  BillPostingRepository(this._db);

  final AppDatabase _db;

  /// Posted bills with participant counts and primary-currency totals for the feed.
  Future<List<PostedBillSummary>> listPostedBillSummaries(String ledgerId) async {
    final txs = await listPostedTransactions(ledgerId);
    final lineRepo = LineItemRepository(_db);
    final out = <PostedBillSummary>[];
    for (final t in txs) {
      final participants = await (_db.select(_db.transactionParticipants)
            ..where((x) => x.transactionId.equals(t.id)))
          .get();
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
    final rows = await (_db.select(_db.transactions)
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
  /// Throws if there are no lines, no participants, or payments do not match
  /// line totals (same rules as settlement).
  Future<void> postDraftBill({
    required String ledgerId,
    required String description,
    String category = 'other',
    int? createdAtMs,
    int taxAmountMinor = 0,
    String? receiptSourcePath,
  }) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final lines = await LineItemRepository(_db).listLedgerLines(ledgerId);
    if (lines.isEmpty) {
      throw StateError('empty_bill');
    }

    final participants = await ParticipantRepository(_db).listParticipants(
      ledgerId,
    );
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

    final draftPay = DraftPaymentRepository(_db);
    await draftPay.pruneExcludedDraftPayments(ledgerId, includedIds);
    var paymentRows = await draftPay.listForDraft(ledgerId);

    final totals = await draftPay.draftLineTotalsByCurrency(ledgerId);

    final lineTotalsForValidate = <rust.LineTotalMinor>[];
    for (final e in totals.entries) {
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
    final payerId =
        participants.firstWhere((p) => includedIds.contains(p.id)).id;
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
      totals,
      fallbackWhenEmpty: _fallbackCurrencyFromLines(lines),
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final postedId = const Uuid().v4();
    final atMs = createdAtMs ?? now;
    final persistedReceipt = await persistReceiptImageFromPath(receiptSourcePath);

    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              id: postedId,
              ledgerId: ledgerId,
              description: Value(description.trim()),
              category: Value(category),
              taxAmountMinor: Value(taxAmountMinor),
              currencyCode: Value(primaryCcy),
              kind: const Value('normal'),
              createdAtMs: atMs,
              updatedAtMs: now,
              receiptImagePath: Value(persistedReceipt),
            ),
          );

      for (final p in participants) {
        if (!includedIds.contains(p.id)) continue;
        await _db.into(_db.transactionParticipants).insert(
              TransactionParticipantsCompanion.insert(
                transactionId: postedId,
                participantId: p.id,
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

  String _fallbackCurrencyFromLines(List<LedgerLineItem> lines) {
    if (lines.isEmpty) return 'IDR';
    return lines.first.receiptItem.currencyCode;
  }

  /// Removes a posted transaction and dependent rows; deletes receipt file if any.
  Future<void> deletePostedTransaction(String transactionId) async {
    final row = await (_db.select(_db.transactions)
          ..where((t) => t.id.equals(transactionId)))
        .getSingleOrNull();
    if (row == null) return;
    await deleteReceiptImageFileIfExists(row.receiptImagePath);
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(transactionId)))
        .go();
  }
}
