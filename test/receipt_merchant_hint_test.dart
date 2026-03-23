import 'package:flutter_test/flutter_test.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';
import 'package:splitbae/core/ocr/receipt_merchant_hint.dart';

void main() {
  test('picks first plausible store line after header noise', () {
    const ocr = '''
THE RUSTIC FORK BISTRO
ABN 12 345 678 910
123 Sample Street
TAX INVOICE
Qty Item Amount
2 Coffee 10.00
''';
    final hint = suggestMerchantNameFromReceiptOcr(
      ocr,
      region: ReceiptParseRegion.auNz,
    );
    expect(hint, 'THE RUSTIC FORK BISTRO');
  });

  test('returns simple two-word merchant', () {
    const ocr = 'Coffee Lab\nFlat White 5.50';
    final hint = suggestMerchantNameFromReceiptOcr(
      ocr,
      region: ReceiptParseRegion.intlEn,
    );
    expect(hint, 'Coffee Lab');
  });

  test('skips table and tax invoice lines', () {
    const ocr = '''
TAX INVOICE
Table: 4
GOURMET PLAZA
Item 1 2.00
''';
    final hint = suggestMerchantNameFromReceiptOcr(
      ocr,
      region: ReceiptParseRegion.sg,
    );
    expect(hint, 'GOURMET PLAZA');
  });

  test('returns null when only summary lines', () {
    const ocr = 'TOTAL 10.00\nGST 0.91';
    final hint = suggestMerchantNameFromReceiptOcr(
      ocr,
      region: ReceiptParseRegion.auNz,
    );
    expect(hint, isNull);
  });
}
