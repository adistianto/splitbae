import 'package:flutter_test/flutter_test.dart';
import 'package:splitbae/core/data/backup_payload_v1.dart';
import 'package:splitbae/core/database/app_database.dart';

void main() {
  test('BackupPayloadV1 JSON roundtrip', () {
    final payload = BackupPayloadV1(
      exportedAtUtcMs: 1700000000000,
      ledgers: const [
        Ledger(
          id: 'l1',
          name: 'Trip',
          createdAtMs: 1,
          updatedAtMs: 2,
        ),
      ],
      participants: const [
        Participant(
          id: 'p1',
          ledgerId: 'l1',
          displayName: 'Ada',
          sortOrder: 0,
          createdAtMs: 3,
        ),
      ],
      receiptLines: const [
        ReceiptLine(
          id: 'r1',
          ledgerId: 'l1',
          label: 'Coffee',
          amountMinor: 5000,
          currencyCode: 'IDR',
          createdAtMs: 4,
          updatedAtMs: 5,
        ),
      ],
    );

    final decoded = BackupPayloadV1.fromJsonString(payload.toJsonString());
    expect(decoded.exportedAtUtcMs, payload.exportedAtUtcMs);
    expect(decoded.ledgers, hasLength(1));
    expect(decoded.ledgers.single.id, 'l1');
    expect(decoded.participants.single.displayName, 'Ada');
    expect(decoded.receiptLines.single.amountMinor, 5000);
  });
}
