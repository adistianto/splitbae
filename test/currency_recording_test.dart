import 'package:flutter_test/flutter_test.dart';
import 'package:splitbae/core/data/currency_recording.dart';

void main() {
  test('pickDominantCurrencyCode chooses largest total', () {
    expect(
      pickDominantCurrencyCode(
        {'IDR': 100, 'USD': 5000},
        fallbackWhenEmpty: 'IDR',
      ),
      'USD',
    );
  });

  test('pickDominantCurrencyCode uses fallback when map empty', () {
    expect(
      pickDominantCurrencyCode(
        {},
        fallbackWhenEmpty: 'AUD',
      ),
      'AUD',
    );
  });
}
