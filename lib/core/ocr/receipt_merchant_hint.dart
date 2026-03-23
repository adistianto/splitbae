import 'package:splitbae/core/ocr/receipt_line_parse.dart';

/// Best-effort merchant / store name from the **top** of OCR text for prefilling
/// bill description. Returns [null] when no line looks like a plausible header.
///
/// Does not run [refineOcrText] on the whole block — that helper fixes trailing
/// price tokens and can mangle words ending in "O" (e.g. "BISTRO").
String? suggestMerchantNameFromReceiptOcr(
  String rawOcrText, {
  ReceiptParseRegion region = ReceiptParseRegion.intlEn,
}) {
  final text =
      rawOcrText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final lines = text
      .split('\n')
      .map((e) => e.trim().replaceAll(RegExp(r' {2,}'), ' '))
      .where((e) => e.isNotEmpty)
      .toList();
  if (lines.isEmpty) return null;

  const maxHeaderLines = 10;
  for (var i = 0; i < lines.length && i < maxHeaderLines; i++) {
    final line = lines[i];
    if (_shouldSkipMerchantLine(line, region)) continue;
    final cleaned = _cleanMerchantCandidate(line);
    if (cleaned != null) return cleaned;
  }
  return null;
}

bool _shouldSkipMerchantLine(String line, ReceiptParseRegion region) {
  final t = line.trim();
  if (t.length < 3) return true;
  if (isReceiptMetadataOrFooterRow(t)) return true;
  if (isLikelySummaryTaxTotalRow(t, region)) return true;
  if (isHeuristicReceiptNoiseLine(t, null, region)) return true;
  final lower = t.toLowerCase();
  if (RegExp(r'^\s*table\s*[:#]').hasMatch(lower)) return true;
  if (RegExp(r'^\s*guests?\s*[:#]').hasMatch(lower)) return true;
  if (RegExp(r'^\s*receipt\s*[:#]').hasMatch(lower)) return true;
  if (RegExp(r'^\s*server\s*[:#]').hasMatch(lower)) return true;
  if (RegExp(r'^\s*invoice\s*[:#]').hasMatch(lower)) return true;
  if (RegExp(r'^\s*tax\s+invoice\b').hasMatch(lower)) return true;
  if (RegExp(r'^https?://').hasMatch(lower)) return true;
  if (RegExp(r'^[=*_–—\s]+$').hasMatch(t)) return true;
  return false;
}

String? _cleanMerchantCandidate(String line) {
  var s = line.trim();
  if (s.length > 80) {
    s = s.substring(0, 80).trim();
  }
  final letters = RegExp(r'[a-zA-Z\u00C0-\u024F]').allMatches(s).length;
  if (letters < 2) return null;
  if (RegExp(r'^\d[\d\s.,]*$').hasMatch(s.replaceAll(RegExp(r'\s'), ''))) {
    return null;
  }
  return s;
}
