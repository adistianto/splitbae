import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/src/rust/api/simple.dart';

class ItemsNotifier extends StateNotifier<List<ReceiptItem>> {
  ItemsNotifier()
      : super([
          const ReceiptItem(
            name: 'Nasi Goreng',
            price: 45000,
            currencyCode: 'IDR',
          ),
          const ReceiptItem(
            name: 'Es Teh',
            price: 15000,
            currencyCode: 'IDR',
          ),
        ]);

  void addItem(String name, double price, String currencyCode) {
    state = [
      ...state,
      ReceiptItem(name: name, price: price, currencyCode: currencyCode),
    ];
  }
}

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, List<ReceiptItem>>((ref) {
  return ItemsNotifier();
});

class ParticipantsNotifier extends StateNotifier<List<String>> {
  ParticipantsNotifier() : super(['Adistianto', 'Gemini', 'Nic']);

  void addParticipant(String name) {
    state = [...state, name];
  }
}

final participantsProvider =
    StateNotifierProvider<ParticipantsNotifier, List<String>>((ref) {
  return ParticipantsNotifier();
});

final splitProvider = FutureProvider<List<SplitResult>>((ref) async {
  final participants = ref.watch(participantsProvider);
  final items = ref.watch(itemsProvider);
  return calculateSplit(items: items, participants: participants);
});
