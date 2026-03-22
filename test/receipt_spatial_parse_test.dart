import 'package:flutter_test/flutter_test.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/ocr/receipt_ocr_channel.dart';
import 'package:splitbae/core/ocr/receipt_spatial_parse.dart';

void main() {
  setUpAll(() {
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

  test('groups distant left label + right IDR price into one line', () {
    final result = ReceiptOcrNativeResult(
      text: '',
      lines: [
        const ReceiptOcrTextLine(
          text: 'Nasi Goreng',
          left: 0.04,
          top: 0.31,
          width: 0.22,
          height: 0.028,
        ),
        const ReceiptOcrTextLine(
          text: 'Rp 45.000',
          left: 0.72,
          top: 0.312,
          width: 0.22,
          height: 0.028,
        ),
      ],
    );

    final list = parseReceiptLineCandidatesFromNative(
      result,
      currencyCode: 'IDR',
    );
    expect(list.length, 1);
    expect(list.single.label, 'Nasi Goreng');
    expect(list.single.amountMinor, 45000);
    expect(list.single.namePlaceholder, isFalse);
  });

  test('different vertical bands stay separate rows', () {
    final result = ReceiptOcrNativeResult(
      text: '',
      lines: [
        const ReceiptOcrTextLine(
          text: 'Coffee',
          left: 0.05,
          top: 0.1,
          width: 0.18,
          height: 0.035,
        ),
        const ReceiptOcrTextLine(
          text: '15.000',
          left: 0.75,
          top: 0.102,
          width: 0.18,
          height: 0.035,
        ),
        const ReceiptOcrTextLine(
          text: 'Tea',
          left: 0.05,
          top: 0.28,
          width: 0.12,
          height: 0.035,
        ),
        const ReceiptOcrTextLine(
          text: '12.000',
          left: 0.75,
          top: 0.282,
          width: 0.18,
          height: 0.035,
        ),
      ],
    );

    final list = parseReceiptLineCandidatesFromNative(
      result,
      currencyCode: 'IDR',
    );
    expect(list.length, 2);
    expect(list.map((e) => e.amountMinor).toSet(), {15000, 12000});
  });

  test('drops TOTAL row with fuzzy keyword', () {
    final result = ReceiptOcrNativeResult(
      text: '',
      lines: [
        const ReceiptOcrTextLine(
          text: 'TOTAL',
          left: 0.05,
          top: 0.2,
          width: 0.2,
          height: 0.03,
        ),
        const ReceiptOcrTextLine(
          text: '100.000',
          left: 0.7,
          top: 0.2,
          width: 0.2,
          height: 0.03,
        ),
      ],
    );

    final list = parseReceiptLineCandidatesFromNative(
      result,
      currencyCode: 'IDR',
    );
    expect(list, isEmpty);
  });

  test('placeholder when name is messy but price parses', () {
    final result = ReceiptOcrNativeResult(
      text: '',
      lines: [
        const ReceiptOcrTextLine(
          text: '@@##',
          left: 0.05,
          top: 0.2,
          width: 0.15,
          height: 0.03,
        ),
        const ReceiptOcrTextLine(
          text: '25.000',
          left: 0.75,
          top: 0.2,
          width: 0.18,
          height: 0.03,
        ),
      ],
    );

    final list = parseReceiptLineCandidatesFromNative(
      result,
      currencyCode: 'IDR',
    );
    expect(list.length, 1);
    expect(list.single.namePlaceholder, isTrue);
    expect(list.single.label, isEmpty);
    expect(list.single.amountMinor, 25000);
  });
}
