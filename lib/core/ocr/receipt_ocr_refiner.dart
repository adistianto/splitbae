/// Deterministic cleanup of raw OCR before parsing (on-device, no cloud).
/// Reduces common misreads (O→0 in numeric tails, extra spaces).
String refineOcrText(String raw) {
  var s = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final lines = s.split('\n');
  final out = <String>[];
  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;
    line = line.replaceAll(RegExp(r' {2,}'), ' ');
    line = _fixTrailingPriceToken(line);
    out.add(line);
  }
  return out.join('\n');
}

String _fixTrailingPriceToken(String line) {
  final re = RegExp(r'^(.*?)([\d.,OolI|]+)\s*$');
  final m = re.firstMatch(line);
  if (m == null) return line;
  final prefix = m.group(1) ?? '';
  var tail = m.group(2) ?? '';
  if (!RegExp(r'^[\d.,OolI|]+$').hasMatch(tail)) return line;
  tail = tail
      .replaceAll('O', '0')
      .replaceAll('o', '0')
      .replaceAll('l', '1')
      .replaceAll('I', '1')
      .replaceAll('|', '1');
  return '$prefix$tail'.trimRight();
}
