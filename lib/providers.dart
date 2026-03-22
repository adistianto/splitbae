import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/data/draft_bill_inclusion_repository.dart';
import 'package:splitbae/core/data/draft_payment_repository.dart';
import 'package:splitbae/core/data/bill_posting_repository.dart';
import 'package:splitbae/core/data/ledger_settlement_service.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/domain/participant_entry.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/domain/transaction_detail_data.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/core/database/app_database.dart'
    show SettlementTransfer, TransactionPayment;
import 'package:splitbae/src/rust/api/simple.dart'
    show
        AssignedReceiptLine,
        ParticipantRef,
        SplitResult,
        calculateSplitAssigned;
import 'package:splitbae/src/rust/api/settlement.dart'
    show NetBalance, SettlementEdge;

/// Bumped after [DraftPaymentRepository.syncDraftPaymentsWithBill] changes
/// `transaction_payments` without necessarily updating [itemsProvider] /
/// [participantsProvider] state. Do not `invalidate` [draftTransactionPaymentsProvider]
/// from those notifiers — it watches them and Riverpod throws [CircularDependencyError].
final draftPaymentsDbRevisionProvider = StateProvider<int>((ref) => 0);

/// Bumped when the posted-bills feed must refresh but [itemsProvider] may be unchanged.
final postedBillsFeedRevisionProvider = StateProvider<int>((ref) => 0);

void _bumpDraftPaymentsDbRevision(Ref ref) {
  ref.read(draftPaymentsDbRevisionProvider.notifier).state++;
}

void _bumpPostedBillsFeedRevision(Ref ref) {
  ref.read(postedBillsFeedRevisionProvider.notifier).state++;
}

/// Bumped when draft “who’s splitting” inclusion changes (DB + payments).
final draftBillInclusionRevisionProvider = StateProvider<int>((ref) => 0);

/// Phone shell: shared search query for Bills + Balances (v0 [page.tsx]).
final v0ShellSearchQueryProvider = StateProvider<String>((ref) => '');

/// True while the Bills filter bottom sheet is open — hides shell search/profile (v0).
final v0BillsFiltersSheetOpenProvider = StateProvider<bool>((ref) => false);

class ItemsNotifier extends StateNotifier<List<LedgerLineItem>> {
  ItemsNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  /// Draft bill’s recording currency ([Transactions.currencyCode] for the draft row).
  String _draftBillCurrencyCode = 'IDR';

  /// ISO 4217 code for the in-progress bill; matches every line on the draft.
  String get draftBillCurrencyCode => _draftBillCurrencyCode;

  Future<void> _load() async {
    final repo = _ref.read(lineItemRepositoryProvider);
    state = await repo.listLedgerLines(kDefaultLedgerId);
    await repo.syncDraftTransactionRecordingCurrency(
      ledgerId: kDefaultLedgerId,
      defaultWhenNoLines: _ref.read(defaultCurrencyProvider),
    );
    _draftBillCurrencyCode =
        await repo.getDraftTransactionCurrencyCode(kDefaultLedgerId);
    await DraftPaymentRepository(_ref.read(appDatabaseProvider))
        .syncDraftPaymentsWithBill(kDefaultLedgerId);
    _bumpDraftPaymentsDbRevision(_ref);
  }

  /// Returns the new line id (for assignment rows after insert).
  Future<String> addItem(
    String name,
    double price, {
    int quantity = 1,
  }) async {
    final repo = _ref.read(lineItemRepositoryProvider);
    final id = await repo.addLine(
      ledgerId: kDefaultLedgerId,
      label: name,
      amount: price,
      quantity: quantity,
    );
    await _load();
    return id;
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required double price,
    int quantity = 1,
  }) async {
    final repo = _ref.read(lineItemRepositoryProvider);
    await repo.updateLine(
      id: id,
      label: name,
      amount: price,
      quantity: quantity,
    );
    await _load();
  }

  Future<void> deleteItem(String id) async {
    await _ref.read(lineItemRepositoryProvider).deleteLine(id);
    await _load();
  }

  Future<void> setLineAssignments({
    required String lineId,
    required Set<String> selectedParticipantIds,
  }) async {
    final all = _ref.read(participantsProvider);
    final effective = await DraftBillInclusionRepository(
      _ref.read(appDatabaseProvider),
    ).effectiveIncludedIds(kDefaultLedgerId, all);
    final repo = _ref.read(lineItemRepositoryProvider);
    await repo.replaceLineAssignments(
      lineId: lineId,
      selectedParticipantIds: selectedParticipantIds,
      allParticipantIds: effective,
    );
    await _load();
  }

  /// After the on-disk database is recreated (e.g. encryption mode change).
  Future<void> reloadFromDatabase() => _load();

  /// Commits the draft bill to history and reloads the empty draft.
  Future<void> postDraftBill(
    String description, {
    String category = 'other',
    int? createdAtMs,
    int taxAmountMinor = 0,
    String? receiptSourcePath,
  }) async {
    await _ref.read(billPostingRepositoryProvider).postDraftBill(
          ledgerId: kDefaultLedgerId,
          description: description,
          category: category,
          createdAtMs: createdAtMs,
          taxAmountMinor: taxAmountMinor,
          receiptSourcePath: receiptSourcePath,
        );
    await _load();
    _bumpPostedBillsFeedRevision(_ref);
  }

  Future<void> deletePostedBill(String transactionId) async {
    await _ref
        .read(billPostingRepositoryProvider)
        .deletePostedTransaction(transactionId);
    _bumpPostedBillsFeedRevision(_ref);
    _ref.invalidate(transactionDetailProvider(transactionId));
  }

  /// Replaces the current draft with a copy of a posted bill (lines, inclusion,
  /// payments, metadata). Used for v0-style “adjust in draft” without mutating history.
  Future<void> copyPostedBillToDraft(String postedTransactionId) async {
    await _ref.read(billPostingRepositoryProvider).copyPostedTransactionToDraft(
          ledgerId: kDefaultLedgerId,
          postedTransactionId: postedTransactionId,
        );
    _ref.read(draftBillInclusionRevisionProvider.notifier).state++;
    _bumpDraftPaymentsDbRevision(_ref);
    await _load();
  }
}

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, List<LedgerLineItem>>((ref) {
      return ItemsNotifier(ref);
    });

/// Recording currency for the current draft bill (one per transaction; not per line in UI).
final draftBillCurrencyProvider = Provider<String>((ref) {
  ref.watch(itemsProvider);
  ref.watch(defaultCurrencyProvider);
  return ref.read(itemsProvider.notifier).draftBillCurrencyCode;
});

class ParticipantsNotifier extends StateNotifier<List<ParticipantEntry>> {
  ParticipantsNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final repo = _ref.read(participantRepositoryProvider);
    state = await repo.listParticipants(kDefaultLedgerId);
    await DraftPaymentRepository(_ref.read(appDatabaseProvider))
        .syncDraftPaymentsWithBill(kDefaultLedgerId);
    _bumpDraftPaymentsDbRevision(_ref);
  }

  Future<void> addParticipant(String name) async {
    await _ref.read(participantRepositoryProvider).addParticipant(name);
    await _load();
  }

  Future<void> renameParticipant({
    required String id,
    required String displayName,
  }) async {
    await _ref
        .read(participantRepositoryProvider)
        .updateDisplayName(participantId: id, displayName: displayName);
    await _load();
  }

  Future<void> removeParticipant(String id) async {
    await _ref.read(participantRepositoryProvider).deleteParticipant(id);
    await _load();
  }

  Future<void> reloadFromDatabase() => _load();
}

final participantsProvider =
    StateNotifierProvider<ParticipantsNotifier, List<ParticipantEntry>>((ref) {
      return ParticipantsNotifier(ref);
    });

/// Ledger participants **on the current draft bill** (subset when toggled).
final draftBillActiveParticipantsProvider =
    FutureProvider<List<ParticipantEntry>>((ref) async {
  ref.watch(participantsProvider);
  ref.watch(draftBillInclusionRevisionProvider);
  final all = ref.read(participantsProvider);
  final ids = await DraftBillInclusionRepository(
    ref.read(appDatabaseProvider),
  ).effectiveIncludedIds(kDefaultLedgerId, all);
  return all.where((p) => ids.contains(p.id)).toList();
});

final splitProvider = FutureProvider<List<SplitResult>>((ref) async {
  final participants = await ref.watch(draftBillActiveParticipantsProvider.future);
  final items = ref.watch(itemsProvider);
  return calculateSplitAssigned(
    lines: items
        .map(
          (e) => AssignedReceiptLine(
            item: e.receiptItem,
            assigneeIds: e.assignedParticipantIds,
          ),
        )
        .toList(),
    participants: participants
        .map(
          (e) => ParticipantRef(id: e.id, displayName: e.displayName),
        )
        .toList(),
  );
});

/// Recorded settlement rows (invalidated after [SettlementRepository.recordTransfer]).
final settlementTransfersListProvider =
    FutureProvider.autoDispose<List<SettlementTransfer>>((ref) async {
  final repo = ref.watch(settlementRepositoryProvider);
  return repo.listForLedger(kDefaultLedgerId);
});

/// Draft bill payment rows (per participant × currency), synced after items/participants load.
final draftTransactionPaymentsProvider =
    FutureProvider.autoDispose<List<TransactionPayment>>((ref) async {
  ref.watch(draftPaymentsDbRevisionProvider);
  ref.watch(itemsProvider);
  ref.watch(participantsProvider);
  final db = ref.watch(appDatabaseProvider);
  return DraftPaymentRepository(db).listForDraft(kDefaultLedgerId);
});

/// Posted bills for the default ledger (feed + detail), newest first.
final postedBillSummariesProvider =
    FutureProvider.autoDispose<List<PostedBillSummary>>((ref) async {
  ref.watch(postedBillsFeedRevisionProvider);
  ref.watch(itemsProvider);
  final db = ref.watch(appDatabaseProvider);
  return BillPostingRepository(db).listPostedBillSummaries(kDefaultLedgerId);
});

/// Loads a single posted transaction for the detail screen.
final transactionDetailProvider =
    FutureProvider.autoDispose.family<TransactionDetailData?, String>((
  ref,
  transactionId,
) async {
  ref.watch(participantsProvider);
  return ref.read(transactionDetailRepositoryProvider).loadDetail(
        ledgerId: kDefaultLedgerId,
        transactionId: transactionId,
      );
});

/// Split math for a posted transaction (same rules as the draft bill).
final postedTransactionSplitProvider =
    Provider.autoDispose.family<List<SplitResult>, String>((ref, txId) {
  final detailAsync = ref.watch(transactionDetailProvider(txId));
  return detailAsync.when(
    data: (d) {
      if (d == null || d.lines.isEmpty) return [];
      final refs = d.transactionParticipantIds
          .map(
            (id) => ParticipantRef(
              id: id,
              displayName: d.participantNames[id] ?? '',
            ),
          )
          .toList();
      return calculateSplitAssigned(
        lines: d.lines
            .map(
              (e) => AssignedReceiptLine(
                item: e.receiptItem,
                assigneeIds: e.assignedParticipantIds,
              ),
            )
            .toList(),
        participants: refs,
      );
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Rust minimal settlement edges from current ledger nets (items + participants + DB).
final suggestedSettlementEdgesProvider =
    FutureProvider.autoDispose<List<SettlementEdge>>((ref) async {
  ref.watch(itemsProvider);
  ref.watch(participantsProvider);
  ref.watch(draftBillInclusionRevisionProvider);
  ref.watch(settlementTransfersListProvider);
  ref.watch(draftTransactionPaymentsProvider);
  final svc = LedgerSettlementService(ref.watch(appDatabaseProvider));
  return svc.suggestedEdges(kDefaultLedgerId);
});

/// Per-participant net balances by currency (draft + posted + settlements).
final ledgerNetBalancesProvider =
    FutureProvider.autoDispose<List<NetBalance>>((ref) async {
  ref.watch(itemsProvider);
  ref.watch(participantsProvider);
  ref.watch(draftBillInclusionRevisionProvider);
  ref.watch(settlementTransfersListProvider);
  ref.watch(draftTransactionPaymentsProvider);
  final svc = LedgerSettlementService(ref.watch(appDatabaseProvider));
  return svc.computeNetBalances(kDefaultLedgerId);
});
