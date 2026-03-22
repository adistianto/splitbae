import 'package:flutter_test/flutter_test.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';

void main() {
  setUpAll(() {
    // VM tests do not load `rust_lib_splitbae`; mirror Rust minor-unit rules here.
    debugSetAmountMinorOverridesForTest(
      amountToMinor: (amount, currencyCode) {
        final c = currencyCode.toUpperCase();
        if (c == 'IDR' || c == 'JPY' || c == 'KRW') {
          return amount.round();
        }
        return (amount * 100).round();
      },
      minorToAmount: (minor, currencyCode) {
        final c = currencyCode.toUpperCase();
        if (c == 'IDR' || c == 'JPY' || c == 'KRW') {
          return minor.toDouble();
        }
        return minor / 100.0;
      },
    );
  });

  tearDownAll(() {
    debugSetAmountMinorOverridesForTest();
  });

  test('parseReceiptLineCandidates extracts trailing amounts (IDR)', () {
    const ocr = '''
Nasi Goreng    45000
Es Teh 15000
Kopi 25000
''';
    final list = parseReceiptLineCandidates(ocr, currencyCode: 'IDR');
    expect(list.length, 3);
    expect(list[0].label, 'Nasi Goreng');
    expect(list[0].amountMinor, 45000);
    expect(list[1].label, 'Es Teh');
    expect(list[1].amountMinor, 15000);
    expect(list[2].label, 'Kopi');
    expect(list[2].amountMinor, 25000);
  });

  test('parse USD decimal lines', () {
    const ocr = 'Coffee 3.50\nTea 2.00';
    final list = parseReceiptLineCandidates(ocr, currencyCode: 'USD');
    expect(list.length, 2);
    expect(list[0].amountMinor, amountToMinorUnits(3.5, 'USD'));
    expect(list[1].amountMinor, amountToMinorUnits(2, 'USD'));
  });

  test('parseReceiptLineCandidates returns empty when no amounts', () {
    expect(parseReceiptLineCandidates('no numbers here'), isEmpty);
  });

  test('IDR uses dot as thousands separator on receipt tails', () {
    const ocr = 'Nasi Goreng 15.000\nMie Ayam 20.000';
    final list = parseReceiptLineCandidates(ocr, currencyCode: 'IDR');
    expect(list.length, 2);
    expect(list[0].label, 'Nasi Goreng');
    expect(list[0].amountMinor, 15000);
    expect(list[1].label, 'Mie Ayam');
    expect(list[1].amountMinor, 20000);
  });

  test('IDR groups multiple thousand dots', () {
    final list = parseReceiptLineCandidates(
      'Pembayaran 1.234.567',
      currencyCode: 'IDR',
    );
    expect(list.length, 1);
    expect(list.first.amountMinor, 1234567);
  });

  test('Qty / Item / Amount table: nine food lines, no metadata or totals', () {
    const ocr = '''
THE RUSTIC FORK BISTRO
ABN 12 345 678 910
123 Flinders Lane, Melbourne VIC 3000
TAX INVOICE
Table: 14
Guests: 5
Receipt: #88421
Date: 21/03/2026 7:42 PM
Qty Item Amount (AUD)
--------------------------------
2 SOURDOUGH G&H 24.00
1 GRAZING PLATTER 38.00
3 LRG FRIES W/ AIOLI 42.00
2 WAGYU BURGER 56.00
1 SEARED BARRA 34.00
2 PUMPKIN RISOTTO 52.00
3 PINT CARLTON 40.50
1 ESPRESSO MARTINI 21.00
1 LEMON LIME BITTERS 6.50
--------------------------------
TOTAL \$314.00
GST INCL. (10%) \$28.55
Thank you for dining with us!
''';

    final list = parseReceiptLineCandidates(ocr, currencyCode: 'AUD');
    expect(list.length, 9);

    expect(list[0].label, 'SOURDOUGH G&H');
    expect(list[0].quantity, 2);
    expect(list[0].amountMinor, amountToMinorUnits(24.00, 'AUD'));
    expect(list[0].unitPriceMajor('AUD'), closeTo(12.00, 1e-6));

    expect(list[1].label, 'GRAZING PLATTER');
    expect(list[1].quantity, 1);
    expect(list[1].amountMinor, amountToMinorUnits(38.00, 'AUD'));

    expect(list[7].label, 'ESPRESSO MARTINI');
    expect(list[7].quantity, 1);
    expect(list[7].amountMinor, amountToMinorUnits(21.00, 'AUD'));

    expect(list[8].label, 'LEMON LIME BITTERS');
    expect(list[8].amountMinor, amountToMinorUnits(6.50, 'AUD'));
  });

  test('heuristic rejects TOTAL and GST lines mixed with real lines', () {
    const ocr = '''
Beer 5.00
TOTAL 5.00
GST 0.45
''';
    final list = parseReceiptLineCandidates(ocr, currencyCode: 'AUD');
    expect(list.length, 1);
    expect(list.first.label, 'Beer');
    expect(list.first.amountMinor, amountToMinorUnits(5.0, 'AUD'));
  });

  test('merges OCR-broken qty rows split across two lines', () {
    const ocr = '''
Qty Item Amount (AUD)
3 LRG FRIES W/
AIOLI 42.00
''';
    final list = parseReceiptLineCandidates(ocr, currencyCode: 'AUD');
    expect(list.length, 1);
    expect(list.single.label, 'LRG FRIES W/ AIOLI');
    expect(list.single.quantity, 3);
    expect(list.single.amountMinor, amountToMinorUnits(42.0, 'AUD'));
  });

  test('merges qty-led line with orphan amount on the next line', () {
    const ocr = '''
2 SOURDOUGH G&H
24.00
''';
    final list = parseReceiptLineCandidates(ocr, currencyCode: 'AUD');
    expect(list.length, 1);
    expect(list.single.quantity, 2);
    expect(list.single.amountMinor, amountToMinorUnits(24.0, 'AUD'));
  });

  test('headerless qty rows without Qty header when pattern is consistent', () {
    const ocr = '''
2 SOURDOUGH G&H 24.00
1 GRAZING PLATTER 38.00
3 LRG FRIES W/ AIOLI 42.00
TOTAL 104.00
''';
    final list = parseReceiptLineCandidates(ocr, currencyCode: 'AUD');
    expect(list.length, 3);
    expect(list[0].quantity, 2);
    expect(list[0].amountMinor, amountToMinorUnits(24.00, 'AUD'));
  });
}
