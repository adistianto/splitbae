import 'package:splitbae/core/ocr/receipt_ocr_refiner.dart';

/// Heuristic parse of OCR text into (label, amount) candidates for receipt lines.
/// [amount] is the **line total** for that row (qty × unit when a qty column exists).
/// [quantity] is set when a Qty / Item / Amount table is detected.
class ReceiptLineCandidate {
  const ReceiptLineCandidate({
    required this.label,
    required this.amount,
    this.quantity,
  });

  final String label;
  final double amount;

  /// When parsed from a qty column; otherwise null (treat as 1 for display math).
  final int? quantity;

  /// Unit price when [quantity] is known; otherwise same as [amount].
  double get unitPrice {
    final q = quantity;
    if (q != null && q > 0) return amount / q;
    return amount;
  }
}

/// Parses [ocrText] into line items. [currencyCode] refines numeric tails (e.g. IDR uses `.` as thousands).
List<ReceiptLineCandidate> parseReceiptLineCandidates(
  String ocrText, {
  String? currencyCode,
}) {
  var lines = refineOcrText(ocrText)
      .split(RegExp(r'\r?\n'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  lines = _mergeBrokenTableRows(lines);

  final structured = _parseStructuredReceipt(lines, currencyCode);
  if (structured.isNotEmpty) {
    return structured.length > 40 ? structured.sublist(0, 40) : structured;
  }

  return _parseHeuristicTrailingAmount(lines, currencyCode);
}

/// OCR often splits one table row across lines (e.g. `3 LRG FRIES W/` + `AIOLI 42.00`).
List<String> _mergeBrokenTableRows(List<String> lines) {
  if (lines.length < 2) return lines;
  final out = <String>[];
  var i = 0;
  while (i < lines.length) {
    var cur = lines[i];
    i++;
    while (i < lines.length && _shouldMergeTableContinuation(cur, lines[i])) {
      cur = '${cur.trim()} ${lines[i].trim()}';
      i++;
    }
    out.add(cur);
  }
  return out;
}

bool _lineHasTrailingAmountToken(String line) {
  return RegExp(r'([\d$][\d.,]*)\s*$').firstMatch(line.trim()) != null;
}

/// Join [cur] with [next] when [cur] is a qty-led row missing its amount and
/// [next] supplies the price (or is a lone amount token).
bool _shouldMergeTableContinuation(String cur, String next) {
  final c = cur.trim();
  final n = next.trim();
  if (c.length < 4) return false;
  if (_lineHasTrailingAmountToken(c)) return false;

  final qtyLed = RegExp(r'^\d{1,3}\s+').hasMatch(c);
  if (!qtyLed) return false;

  if (RegExp(r'^([\d$][\d.,]*)\s*$').hasMatch(n)) {
    return true;
  }
  return _lineHasTrailingAmountToken(n);
}

/// Columnar receipts (Qty / Item / Amount) and similar.
List<ReceiptLineCandidate> _parseStructuredReceipt(
  List<String> lines,
  String? currencyCode,
) {
  int? headerLineIndex;
  for (var i = 0; i < lines.length; i++) {
    if (_looksLikeQtyItemAmountHeader(lines[i])) {
      headerLineIndex = i;
      break;
    }
  }

  if (headerLineIndex != null) {
    var tableStart = headerLineIndex + 1;
    while (tableStart < lines.length && _isSeparatorOrNoiseLine(lines[tableStart])) {
      tableStart++;
    }
    final out = _scanTableRows(lines, tableStart, currencyCode, maxQty: 999);
    if (out.isNotEmpty) return out;
  }

  final headerless = _parseHeaderlessQtyRows(lines, currencyCode);
  if (headerless.isNotEmpty) return headerless;

  return const [];
}

List<ReceiptLineCandidate> _scanTableRows(
  List<String> lines,
  int start,
  String? currencyCode, {
  required int maxQty,
}) {
  final out = <ReceiptLineCandidate>[];
  for (var i = start; i < lines.length; i++) {
    final line = lines[i];
    if (_isSeparatorOrNoiseLine(line)) continue;
    if (_shouldStopTableParsing(line)) break;
    final row = _parseQtyItemAmountLine(line, currencyCode, maxQty: maxQty);
    if (row != null) out.add(row);
  }
  return out;
}

/// Rows like `2 SOURDOUGH G&H 24.00` without a header (OCR dropped the header line).
List<ReceiptLineCandidate> _parseHeaderlessQtyRows(
  List<String> lines,
  String? currencyCode,
) {
  final out = <ReceiptLineCandidate>[];
  for (final line in lines) {
    if (_shouldStopTableParsing(line)) continue;
    final row = _parseQtyItemAmountLine(line, currencyCode, maxQty: 48);
    if (row == null) continue;
    if (_isLikelyNonItemLabel(row.label)) continue;
    out.add(row);
  }
  return out;
}

bool _looksLikeQtyItemAmountHeader(String line) {
  final lower = line.toLowerCase();
  if (!lower.contains('qty')) return false;
  if (lower.contains('item') ||
      lower.contains('description') ||
      lower.contains('amount') ||
      lower.contains('aud') ||
      lower.contains('usd')) {
    return true;
  }
  return false;
}

bool _isSeparatorOrNoiseLine(String line) {
  final t = line.trim();
  if (t.length < 3) return true;
  if (RegExp(r'^[-–—=\s.]+$').hasMatch(t)) return true;
  final nonDash = t.replaceAll(RegExp(r'[-–—=\s.]'), '');
  return nonDash.isEmpty;
}

bool _shouldStopTableParsing(String line) {
  final t = line.trim().toLowerCase();
  if (t.isEmpty) return false;
  if (RegExp(r'^\s*total\b').hasMatch(t) && !t.startsWith('subtotal')) {
    return true;
  }
  if (RegExp(r'^\s*grand\s+total\b').hasMatch(t)) return true;
  if (RegExp(r'^\s*gst\b').hasMatch(t)) return true;
  if (RegExp(r'^\s*tax\b').hasMatch(t) && !t.contains('invoice')) return true;
  if (RegExp(r'^\s*amount\s+due\b').hasMatch(t)) return true;
  if (RegExp(r'^\s*balance\b').hasMatch(t)) return true;
  if (RegExp(r'^\s*payment\b').hasMatch(t)) return true;
  if (RegExp(r'^\s*tip\b').hasMatch(t)) return true;
  if (RegExp(r'thank\s+you').hasMatch(t)) return true;
  return false;
}

ReceiptLineCandidate? _parseQtyItemAmountLine(
  String line,
  String? currencyCode, {
  required int maxQty,
}) {
  final trimmed = line.trim();
  if (trimmed.length < 4) return null;

  final amountMatch = RegExp(r'([\d$][\d.,]*)\s*$').firstMatch(trimmed);
  if (amountMatch == null) return null;

  var numStr = amountMatch.group(1)!;
  numStr = numStr.replaceAll(r'$', '').trim();
  if (numStr.isEmpty) return null;

  final amt = _normalizeAndParseAmount(numStr, currencyCode);
  if (amt == null || amt <= 0 || amt > 1e12) return null;

  final beforeAmount = trimmed.substring(0, amountMatch.start).trim();
  final qtyMatch = RegExp(r'^(\d{1,3})\s+(.+)$').firstMatch(beforeAmount);
  if (qtyMatch == null) return null;

  final q = int.tryParse(qtyMatch.group(1)!);
  if (q == null || q < 1 || q > maxQty) return null;

  var name = qtyMatch.group(2)!.trim();
  name = name.replaceAll(RegExp(r'^[-–—•\s]+'), '').trim();
  if (name.length < 2) return null;
  if (_isLikelyNonItemLabel(name)) return null;

  return ReceiptLineCandidate(label: name, amount: amt, quantity: q);
}

bool _isLikelyNonItemLabel(String name) {
  final lower = name.toLowerCase();
  if (RegExp(
    r'^(table|guests|date|time|receipt|invoice|server|abn|subtotal|total)\b',
  ).hasMatch(lower)) {
    return true;
  }
  if (RegExp(r'\babn\b').hasMatch(lower)) return true;
  if (RegExp(r'\btax\s+invoice\b').hasMatch(lower)) return true;
  if (RegExp(r'melbourne|flinders\s+lane|\bvic\s+\d{4}\b').hasMatch(lower)) {
    return true;
  }
  return false;
}

List<ReceiptLineCandidate> _parseHeuristicTrailingAmount(
  List<String> lines,
  String? currencyCode,
) {
  final out = <ReceiptLineCandidate>[];
  final amountRe = RegExp(r'([\d$][\d.,]*)\s*$');

  for (final line in lines) {
    final m = amountRe.firstMatch(line);
    if (m == null) continue;
    var numStr = m.group(1)!;
    numStr = numStr.replaceAll(r'$', '').trim();
    if (numStr.isEmpty) continue;

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

    final amt = _parseAmountWithCurrencyHint(numStr, currencyCode);
    if (amt == null || amt <= 0 || amt > 1e12) continue;

    var label = line.substring(0, m.start).trim();
    label = label.replaceAll(RegExp(r'^[-–—•\s]+'), '').trim();
    if (label.isEmpty) continue;
    if (_shouldRejectHeuristicLine(label, amt)) continue;

    out.add(ReceiptLineCandidate(label: label, amount: amt));
  }
  return out.length > 20 ? out.sublist(0, 20) : out;
}

bool _shouldRejectHeuristicLine(String label, double amount) {
  final l = label.toLowerCase().trim();

  if (RegExp(
    r'^(total|subtotal|sub-total|sub\s+total|gst|tax|balance|change|cash|tip)\b',
  ).hasMatch(l)) {
    return true;
  }
  if (RegExp(r'^(amount|qty|item|items)\b').hasMatch(l)) return true;
  if (RegExp(
    r'\b(visa|mastercard|eftpos|efpos|surcharge|service\s*charge)\b',
  ).hasMatch(l)) {
    return true;
  }
  if (RegExp(r'\babn\b').hasMatch(l)) return true;
  if (RegExp(r'^(date|time|receipt|server|table|guests)\s*[:#]').hasMatch(l)) {
    return true;
  }
  if (RegExp(r'melbourne|flinders\s+lane|\bvic\s+\d{4}\b').hasMatch(l)) {
    return true;
  }
  if (RegExp(r'\btax\s+invoice\b').hasMatch(l)) return true;
  if (l.length <= 2 && RegExp(r'^\d+$').hasMatch(l)) return true;

  return false;
}

double? _normalizeAndParseAmount(String raw, String? currencyCode) {
  var numStr = raw;
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
  return _parseAmountWithCurrencyHint(numStr, currencyCode);
}

double? _parseAmountWithCurrencyHint(String numStr, String? currencyCode) {
  if (currencyCode == 'IDR') {
    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(numStr)) {
      return double.tryParse(numStr.replaceAll('.', ''));
    }
  }
  return double.tryParse(numStr);
}
