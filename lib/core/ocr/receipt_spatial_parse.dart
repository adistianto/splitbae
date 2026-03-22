import 'dart:math' as math;

import 'package:splitbae/core/ocr/receipt_line_parse.dart';
import 'package:splitbae/core/ocr/receipt_ocr_channel.dart';
import 'package:splitbae/core/ocr/receipt_ocr_refiner.dart';

/// Uses native line bounding boxes to group far-apart name + price into one
/// [ReceiptLineCandidate], then falls back to [parseReceiptLineCandidates] when
/// bounds are missing or nothing survives filters.
List<ReceiptLineCandidate> parseReceiptLineCandidatesFromNative(
  ReceiptOcrNativeResult result, {
  String? currencyCode,
}) {
  final cc = (currencyCode == null || currencyCode.trim().isEmpty)
      ? 'IDR'
      : currencyCode.trim();

  final usable =
      result.lines.where((l) => l.text.trim().isNotEmpty).toList();
  if (usable.isEmpty) {
    return parseReceiptLineCandidates(result.text, currencyCode: cc);
  }

  if (!usable.any(_hasUsableBounds)) {
    return parseReceiptLineCandidates(result.text, currencyCode: cc);
  }

  final spatial = _withSyntheticBoundsWhereNeeded(usable);
  final rows = _clusterVisualRows(spatial);
  rows.sort((a, b) => _meanTop(a).compareTo(_meanTop(b)));

  final out = <ReceiptLineCandidate>[];
  for (final row in rows) {
    final c = _candidateFromVisualRow(row, cc);
    if (c != null) out.add(c);
  }

  if (out.isEmpty) {
    return parseReceiptLineCandidates(result.text, currencyCode: cc);
  }

  return out.length > 40 ? out.sublist(0, 40) : out;
}

bool _hasUsableBounds(ReceiptOcrTextLine l) {
  return l.left != null &&
      l.top != null &&
      l.width != null &&
      l.height != null &&
      l.height! > 1e-6 &&
      l.width! > 1e-6;
}

class _BoxLine {
  _BoxLine(this.source, this.left, this.top, this.width, this.height);

  final ReceiptOcrTextLine source;
  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
}

List<_BoxLine> _withSyntheticBoundsWhereNeeded(List<ReceiptOcrTextLine> lines) {
  var synthTop = 0.0;
  const rowH = 0.035;
  const gap = 0.008;
  final out = <_BoxLine>[];
  for (final l in lines) {
    if (_hasUsableBounds(l)) {
      out.add(_BoxLine(l, l.left!, l.top!, l.width!, l.height!));
    } else {
      out.add(_BoxLine(l, 0.02, synthTop, 0.96, rowH));
      synthTop += rowH + gap;
    }
  }
  return out;
}

bool _verticalOverlapExceedsHalfMinHeight(_BoxLine a, _BoxLine b) {
  final top = math.max(a.top, b.top);
  final bottom = math.min(a.bottom, b.bottom);
  final overlap = bottom - top;
  if (overlap <= 0) return false;
  final minH = math.min(a.height, b.height);
  if (minH <= 1e-9) return false;
  return overlap > 0.5 * minH;
}

class _UnionFind {
  _UnionFind(int n) : _p = List.generate(n, (i) => i);

  final List<int> _p;

  int find(int i) {
    if (_p[i] != i) _p[i] = find(_p[i]);
    return _p[i];
  }

  void union(int a, int b) {
    final ra = find(a);
    final rb = find(b);
    if (ra != rb) _p[ra] = rb;
  }
}

List<List<_BoxLine>> _clusterVisualRows(List<_BoxLine> lines) {
  final n = lines.length;
  final uf = _UnionFind(n);
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      if (_verticalOverlapExceedsHalfMinHeight(lines[i], lines[j])) {
        uf.union(i, j);
      }
    }
  }
  final map = <int, List<_BoxLine>>{};
  for (var i = 0; i < n; i++) {
    final r = uf.find(i);
    map.putIfAbsent(r, () => []).add(lines[i]);
  }
  return map.values.toList();
}

double _meanTop(List<_BoxLine> row) {
  var s = 0.0;
  for (final e in row) {
    s += e.top;
  }
  return s / row.length;
}

class _PriceHit {
  _PriceHit({required this.start, required this.end, required this.minor});

  final int start;
  final int end;
  final int minor;
}

_PriceHit? _findRightmostPriceHit(String combined, String cc) {
  final hits = <_PriceHit>[];

  final currencyFirst = RegExp(
    r'(?:Rp\.?\s*|IDR\s*|USD\s*|US\$|AUD\s*|SGD\s*|EUR\s*|€\s*|\$\s*)([\d][\d.,OolI|]*)',
    caseSensitive: false,
  );
  for (final m in currencyFirst.allMatches(combined)) {
    final g = m.group(1);
    if (g == null) continue;
    final minor = tryParseMoneyTokenToMinorUnits(g, cc);
    if (minor == null || minor <= 0) continue;
    hits.add(_PriceHit(start: m.start, end: m.end, minor: minor));
  }

  final trailEnd = RegExp(r'([\d][\d.,]{2,})\s*$').firstMatch(combined);
  if (trailEnd != null) {
    final g = trailEnd.group(1)!;
    final minor = tryParseMoneyTokenToMinorUnits(g, cc);
    if (minor != null && minor > 0) {
      hits.add(_PriceHit(
        start: trailEnd.start,
        end: trailEnd.end,
        minor: minor,
      ));
    }
  }

  if (hits.isEmpty) return null;
  hits.sort((a, b) {
    final c = a.end.compareTo(b.end);
    if (c != 0) return c;
    return b.start.compareTo(a.start);
  });
  return hits.last;
}

bool _isMessyItemName(String label) {
  final t = label.trim();
  if (t.length < 2) return true;
  final letters = RegExp('[a-zA-Z]').allMatches(t).length;
  if (letters < 2) return true;
  final weird = RegExp(r'[^a-zA-Z0-9\s]').allMatches(t).length;
  if (weird > t.length * 0.55) return true;
  return false;
}

bool _shouldRejectSpatialRow(String combined) {
  final t = combined.trim();
  if (t.length < 3) return true;

  if (isReceiptMetadataOrFooterRow(t)) return true;
  if (isLikelySummaryTaxTotalRow(t)) return true;
  if (isHeuristicReceiptNoiseLine(t, null)) return true;
  return false;
}

ReceiptLineCandidate? _candidateFromVisualRow(List<_BoxLine> row, String cc) {
  row.sort((a, b) => a.left.compareTo(b.left));
  final parts = <String>[];
  for (final box in row) {
    final refined = refineOcrText(box.source.text)
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(' ');
    if (refined.isNotEmpty) parts.add(refined);
  }
  if (parts.isEmpty) return null;

  final combined = parts.join(' ');
  if (_shouldRejectSpatialRow(combined)) return null;

  final hit = _findRightmostPriceHit(combined, cc);
  if (hit == null) return null;

  var label = combined.substring(0, hit.start).trim();
  label = label.replaceAll(RegExp(r'^[-–—•\s.:]+'), '').trim();
  label = label.replaceAll(RegExp(r'[.·…]{2,}\s*$'), '').trim();

  final minor = hit.minor;
  if (minor <= 0) return null;

  var placeholder = false;
  if (label.isEmpty || _isMessyItemName(label)) {
    placeholder = true;
    label = '';
  }

  return ReceiptLineCandidate(
    label: label,
    amountMinor: minor,
    namePlaceholder: placeholder,
  );
}
