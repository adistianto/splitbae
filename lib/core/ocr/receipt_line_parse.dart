import 'package:splitbae/core/ocr/receipt_ocr_refiner.dart';

/// Heuristic parse of OCR text into (label, amount) candidates for receipt lines.
/// Amount is taken from the end of each line (common on printed receipts).
class ReceiptLineCandidate {
  const ReceiptLineCandidate({required this.label, required this.amount});

  final String label;
  final double amount;
}

List<ReceiptLineCandidate> parseReceiptLineCandidates(String ocrText) {
  final lines = refineOcrText(ocrText)
      .split(RegExp(r'\r?\n'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  final out = <ReceiptLineCandidate>[];
  // Trailing number: 12.50 or 12,500 or 12500
  final amountRe = RegExp(r'([\d][\d.,]*)\s*$');
  for (final line in lines) {
    final m = amountRe.firstMatch(line);
    if (m == null) continue;
    var numStr = m.group(1)!;
    // Drop thousand separators; keep one decimal point
    if (numStr.contains(',') && numStr.contains('.')) {
      numStr = numStr.replaceAll(',', '');
    } else if (numStr.contains(',') && !numStr.contains('.')) {
      final parts = numStr.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        numStr = '${parts[0]}.${parts[1]}';
      } else {
        numStr = numStr.replaceAll(',', '');
      }
    } else {
      numStr = numStr.replaceAll(',', '');
    }
    final amt = double.tryParse(numStr);
    if (amt == null || amt <= 0 || amt > 1e12) continue;
    var label = line.substring(0, m.start).trim();
    label = label.replaceAll(RegExp(r'^[-–—•\s]+'), '').trim();
    if (label.isEmpty) continue;
    out.add(ReceiptLineCandidate(label: label, amount: amt));
  }
  return out.length > 20 ? out.sublist(0, 20) : out;
}
