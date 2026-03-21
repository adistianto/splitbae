import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/src/rust/api/simple.dart';

class ItemsNotifier extends StateNotifier<List<ReceiptItem>> {
  ItemsNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final repo = _ref.read(lineItemRepositoryProvider);
    state = await repo.listForLedger(kDefaultLedgerId);
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

  /// After the on-disk database is recreated (e.g. encryption mode change).
  Future<void> reloadFromDatabase() => _load();
}

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, List<ReceiptItem>>((ref) {
  return ItemsNotifier(ref);
});

class ParticipantsNotifier extends StateNotifier<List<String>> {
  ParticipantsNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final repo = _ref.read(participantRepositoryProvider);
    state = await repo.listDisplayNames(kDefaultLedgerId);
  }

  Future<void> addParticipant(String name) async {
    await _ref.read(participantRepositoryProvider).addParticipant(name);
    await _load();
  }

  Future<void> reloadFromDatabase() => _load();
}

final participantsProvider =
    StateNotifierProvider<ParticipantsNotifier, List<String>>((ref) {
  return ParticipantsNotifier(ref);
});

final splitProvider = FutureProvider<List<SplitResult>>((ref) async {
  final participants = ref.watch(participantsProvider);
  final items = ref.watch(itemsProvider);
  return calculateSplit(items: items, participants: participants);
});
