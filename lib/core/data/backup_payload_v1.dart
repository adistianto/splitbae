import 'dart:convert';

import '../database/app_database.dart';

/// On-disk JSON backup (`.sb_backup`). Plain UTF-8 JSON for MVP; store only
/// where you trust (see Settings copy).
class BackupPayloadV1 {
  BackupPayloadV1({
    required this.exportedAtUtcMs,
    required this.ledgers,
    required this.participants,
    required this.receiptLines,
    this.receiptLineAssignments = const [],
  });

  static const String formatId = 'splitbae_backup';
  static const int formatVersion = 1;

  final int exportedAtUtcMs;
  final List<Ledger> ledgers;
  final List<Participant> participants;
  final List<ReceiptLine> receiptLines;
  final List<ReceiptLineAssignment> receiptLineAssignments;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'format': formatId,
      'version': formatVersion,
      'exportedAtUtcMs': exportedAtUtcMs,
      'ledgers': ledgers.map((e) => e.toJson()).toList(),
      'participants': participants.map((e) => e.toJson()).toList(),
      'receiptLines': receiptLines.map((e) => e.toJson()).toList(),
      'receiptLineAssignments':
          receiptLineAssignments.map((e) => e.toJson()).toList(),
    };
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  static BackupPayloadV1 fromJson(Map<String, dynamic> json) {
    final format = json['format'] as String?;
    if (format != formatId) {
      throw FormatException('Not a SplitBae backup (wrong format field)');
    }
    final version = json['version'];
    if (version is! int || version != formatVersion) {
      throw FormatException('Unsupported backup version: $version');
    }
    final exported = json['exportedAtUtcMs'];
    if (exported is! int) {
      throw FormatException('Missing exportedAtUtcMs');
    }
    final ledgersJson = json['ledgers'];
    final participantsJson = json['participants'];
    final linesJson = json['receiptLines'];
    if (ledgersJson is! List ||
        participantsJson is! List ||
        linesJson is! List) {
      throw FormatException('Invalid backup tables');
    }
    return BackupPayloadV1(
      exportedAtUtcMs: exported,
      ledgers: ledgersJson
          .map((e) => Ledger.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      participants: participantsJson
          .map((e) => Participant.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      receiptLines: linesJson
          .map((e) => ReceiptLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      receiptLineAssignments: _parseAssignments(json['receiptLineAssignments']),
    );
  }

  static List<ReceiptLineAssignment> _parseAssignments(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map(
          (e) =>
              ReceiptLineAssignment.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  static BackupPayloadV1 fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Backup root must be a JSON object');
    }
    return BackupPayloadV1.fromJson(decoded);
  }
}
