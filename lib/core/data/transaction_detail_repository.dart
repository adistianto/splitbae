import '../database/app_database.dart';
import '../domain/transaction_detail_data.dart';
import 'line_item_repository.dart';
import 'participant_repository.dart';

class TransactionDetailRepository {
  TransactionDetailRepository(this._db);

  final AppDatabase _db;

  Future<Transaction?> getTransaction(String id) async {
    return (_db.select(_db.transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<TransactionPayment>> listPayments(String transactionId) async {
    return (_db.select(_db.transactionPayments)
          ..where((t) => t.transactionId.equals(transactionId)))
        .get();
  }

  Future<TransactionDetailData?> loadDetail({
    required String ledgerId,
    required String transactionId,
  }) async {
    final t = await getTransaction(transactionId);
    if (t == null) return null;
    final lineRepo = LineItemRepository(_db);
    final lines = await lineRepo.listLinesForTransaction(
      ledgerId: ledgerId,
      transactionId: transactionId,
    );
    final payments = await listPayments(transactionId);
    final participants = await ParticipantRepository(_db).listParticipants(
      ledgerId,
    );
    final names = {for (final p in participants) p.id: p.displayName};
    final tpRows = await (_db.select(_db.transactionParticipants)
          ..where((x) => x.transactionId.equals(transactionId)))
        .get();
    return TransactionDetailData(
      transaction: t,
      lines: lines,
      payments: payments,
      participantNames: names,
      participantCount: tpRows.length,
    );
  }
}
