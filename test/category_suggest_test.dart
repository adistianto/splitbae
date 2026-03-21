import 'package:flutter_test/flutter_test.dart';
import 'package:splitbae/core/suggest/category_from_description.dart';

void main() {
  test('suggestCategoryFromDescription picks food for restaurant', () {
    expect(
      suggestCategoryFromDescription('Dinner at some restaurant'),
      'food',
    );
  });

  test('suggestCategoryFromDescription picks transport for grab', () {
    expect(suggestCategoryFromDescription('Grab to airport'), 'transport');
  });
}
