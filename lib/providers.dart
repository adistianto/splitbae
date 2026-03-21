import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/domain/participant_entry.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/src/rust/api/simple.dart';

class ItemsNotifier extends StateNotifier<List<LedgerLineItem>> {
  ItemsNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final repo = _ref.read(lineItemRepositoryProvider);
    state = await repo.listLedgerLines(kDefaultLedgerId);
  }

  Future<void> addItem(String name, double price, String currencyCode) async {
    final repo = _ref.read(lineItemRepositoryProvider);
    await repo.addLine(
      ledgerId: kDefaultLedgerId,
      label: name,
      amount: price,
      currencyCode: currencyCode,
    );
    await _load();
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
  return calculateSplit(
    items: items.map((e) => e.receiptItem).toList(),
    participants: participants.map((e) => e.displayName).toList(),
  );
});
