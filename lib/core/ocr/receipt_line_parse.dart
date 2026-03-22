import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/ocr/receipt_ocr_refiner.dart';

/// Heuristic parse of OCR text into (label, amount) candidates for receipt lines.
/// [amountMinor] is the **line total** in minor units (qty × unit when a qty column exists).
/// [quantity] is set when a Qty / Item / Amount table is detected.
class ReceiptLineCandidate {
  const ReceiptLineCandidate({
    required this.label,
    required this.amountMinor,
    this.quantity,
  });

  final String label;

  /// Line total in minor units for [currencyCode] (from Rust [amountToMinorUnits] rules).
  final int amountMinor;

  /// When parsed from a qty column; otherwise null (treat as 1 for display math).
  final int? quantity;

  ReceiptLineCandidate copyWith({
    String? label,
    int? amountMinor,
    int? quantity,
  }) {
    return ReceiptLineCandidate(
      label: label ?? this.label,
      amountMinor: amountMinor ?? this.amountMinor,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Unit price in major units when [quantity] is known; otherwise line total.
  double unitPriceMajor(String currencyCode) {
    final q = quantity;
    if (q != null && q > 0) {
      return minorUnitsToAmount(amountMinor, currencyCode) / q;
    }
    return minorUnitsToAmount(amountMinor, currencyCode);
  }

  /// Line total in major units (for persistence / display).
  double lineTotalMajor(String currencyCode) {
    return minorUnitsToAmount(amountMinor, currencyCode);
  }
}

int? _doubleToMinor(double? amt, String? currencyCode) {
  if (amt == null || amt <= 0 || amt > 1e12) return null;
  final cc = currencyCode?.trim();
  if (cc == null || cc.isEmpty) return null;
  return amountToMinorUnits(amt, cc);
}

/// Parses [ocrText] into line items. [currencyCode] refines numeric tails (e.g. IDR uses `.` as thousands).
/// When omitted, **IDR** is assumed (product default).
List<ReceiptLineCandidate> parseReceiptLineCandidates(
  String ocrText, {
  String? currencyCode,
}) {
  final cc = (currencyCode == null || currencyCode.trim().isEmpty)
      ? 'IDR'
      : currencyCode.trim();

  var lines = refineOcrText(ocrText)
      .split(RegExp(r'\r?\n'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  lines = _mergeBrokenTableRows(lines);

  final structured = _parseStructuredReceipt(lines, cc);
  if (structured.isNotEmpty) {
    return structured.length > 40 ? structured.sublist(0, 40) : structured;
  }

  return _parseHeuristicTrailingAmount(lines, cc);
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
  final minor = _doubleToMinor(amt, currencyCode);
  if (minor == null) return null;

  final beforeAmount = trimmed.substring(0, amountMatch.start).trim();
  final qtyMatch = RegExp(r'^(\d{1,3})\s+(.+)$').firstMatch(beforeAmount);
  if (qtyMatch == null) return null;

  final q = int.tryParse(qtyMatch.group(1)!);
  if (q == null || q < 1 || q > maxQty) return null;

  var name = qtyMatch.group(2)!.trim();
  name = name.replaceAll(RegExp(r'^[-–—•\s]+'), '').trim();
  if (name.length < 2) return null;
  if (_isLikelyNonItemLabel(name)) return null;

  return ReceiptLineCandidate(label: name, amountMinor: minor, quantity: q);
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
    final minor = _doubleToMinor(amt, currencyCode);
    if (minor == null) continue;

    var label = line.substring(0, m.start).trim();
    label = label.replaceAll(RegExp(r'^[-–—•\s]+'), '').trim();
    if (label.isEmpty) continue;
    if (_shouldRejectHeuristicLine(label, amt)) continue;

    out.add(ReceiptLineCandidate(label: label, amountMinor: minor));
  }
  return out.length > 20 ? out.sublist(0, 20) : out;
}

bool _shouldRejectHeuristicLine(String label, double? amount) {
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

  // Dates: DD/MM/YYYY, MM-DD-YY, ISO fragments often picked up with amounts.
  if (RegExp(
    r'^\d{1,4}[/.\-]\d{1,4}([/.\-]\d{1,4})?\s*$',
  ).hasMatch(l.trim())) {
    return true;
  }
  if (RegExp(
    r'\b\d{1,2}\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{2,4}\b',
  ).hasMatch(l)) {
    return true;
  }

  // Phone / fax / order numbers (long digit runs without a clear item name).
  if (_looksLikePhoneOrOrderLine(l)) return true;

  // Card last-4 style: ****1234
  if (RegExp(r'\*+\d{4}\b').hasMatch(l)) return true;

  // Register / transaction IDs: "Trans ID: 12345" already caught; lone long numbers.
  if (RegExp(r'^\d{10,}$').hasMatch(l.replaceAll(RegExp(r'\s'), ''))) {
    return true;
  }

  // Very small amounts with no alphabetic label (often OCR garbage).
  if (amount != null &&
      amount < 0.05 &&
      !RegExp(r'[a-zA-Z]{2,}').hasMatch(l)) {
    return true;
  }

  return false;
}

bool _looksLikePhoneOrOrderLine(String l) {
  final digits = l.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 10 &&
      RegExp(r'^[\d\s().+\-]+$').hasMatch(l.replaceAll(RegExp(r'\s+'), ' '))) {
    if (!RegExp(r'[a-zA-Z]{3,}').hasMatch(l)) return true;
  }
  if (RegExp(r'^\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\s*$').hasMatch(l)) {
    return true;
  }
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
