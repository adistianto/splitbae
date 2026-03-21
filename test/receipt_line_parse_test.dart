import 'package:flutter_test/flutter_test.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';

void main() {
  test('parseReceiptLineCandidates extracts trailing amounts', () {
    const ocr = '''
Nasi Goreng    45000
Es Teh 15000
Coffee 3.50
''';
    final list = parseReceiptLineCandidates(ocr);
    expect(list.length, 3);
    expect(list[0].label, 'Nasi Goreng');
    expect(list[0].amount, 45000);
    expect(list[1].label, 'Es Teh');
    expect(list[1].amount, 15000);
    expect(list[2].label, 'Coffee');
    expect(list[2].amount, closeTo(3.5, 1e-9));
  });

  test('parseReceiptLineCandidates returns empty when no amounts', () {
    expect(parseReceiptLineCandidates('no numbers here'), isEmpty);
  });
}
