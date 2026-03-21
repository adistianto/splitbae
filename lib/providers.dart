import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/data/draft_payment_repository.dart';
import 'package:splitbae/core/data/ledger_settlement_service.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/domain/participant_entry.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/core/database/app_database.dart'
    show SettlementTransfer, TransactionPayment;
import 'package:splitbae/src/rust/api/simple.dart'
    show
        AssignedReceiptLine,
        ParticipantRef,
        SplitResult,
        calculateSplitAssigned;
import 'package:splitbae/src/rust/api/settlement.dart' show SettlementEdge;

class ItemsNotifier extends StateNotifier<List<LedgerLineItem>> {
  ItemsNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final repo = _ref.read(lineItemRepositoryProvider);
    state = await repo.listLedgerLines(kDefaultLedgerId);
    await DraftPaymentRepository(_ref.read(appDatabaseProvider))
        .syncDraftPaymentsWithBill(kDefaultLedgerId);
    _ref.invalidate(draftTransactionPaymentsProvider);
  }

  /// Returns the new line id (for assignment rows after insert).
  Future<String> addItem(String name, double price, String currencyCode) async {
    final repo = _ref.read(lineItemRepositoryProvider);
    final id = await repo.addLine(
      ledgerId: kDefaultLedgerId,
      label: name,
      amount: price,
      currencyCode: currencyCode,
    );
    await _load();
    return id;
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required double price,
    required String currencyCode,
  }) async {
    final repo = _ref.read(lineItemRepositoryProvider);
    await repo.updateLine(
      id: id,
      label: name,
      amount: price,
      currencyCode: currencyCode,
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
    final participants = _ref.read(participantsProvider);
    final repo = _ref.read(lineItemRepositoryProvider);
    await repo.replaceLineAssignments(
      lineId: lineId,
      selectedParticipantIds: selectedParticipantIds,
      allParticipantIds: participants.map((e) => e.id).toSet(),
    );
    await _load();
  }

  /// After the on-disk database is recreated (e.g. encryption mode change).
  Future<void> reloadFromDatabase() => _load();
}

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, List<LedgerLineItem>>((ref) {
      return ItemsNotifier(ref);
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
    _ref.invalidate(draftTransactionPaymentsProvider);
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

final splitProvider = FutureProvider<List<SplitResult>>((ref) async {
  final participants = ref.watch(participantsProvider);
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
  ref.watch(itemsProvider);
  ref.watch(participantsProvider);
  final db = ref.watch(appDatabaseProvider);
  return DraftPaymentRepository(db).listForDraft(kDefaultLedgerId);
});

/// Rust minimal settlement edges from current ledger nets (items + participants + DB).
final suggestedSettlementEdgesProvider =
    FutureProvider.autoDispose<List<SettlementEdge>>((ref) async {
  ref.watch(itemsProvider);
  ref.watch(participantsProvider);
  ref.watch(settlementTransfersListProvider);
  ref.watch(draftTransactionPaymentsProvider);
  final svc = LedgerSettlementService(ref.watch(appDatabaseProvider));
  return svc.suggestedEdges(kDefaultLedgerId);
});
