/// Keyword-based category suggestion (aligned with v0 `add-expense-sheet.tsx`).
String? suggestCategoryFromDescription(String description) {
  final lower = description.toLowerCase().trim();
  if (lower.isEmpty) return null;

  const keywords = <String, String>{
    'restaurant': 'food',
    'cafe': 'food',
    'coffee': 'food',
    'lunch': 'food',
    'dinner': 'food',
    'breakfast': 'food',
    'food': 'food',
    'pizza': 'food',
    'burger': 'food',
    'ramen': 'food',
    'sushi': 'food',
    'nasi': 'food',
    'mie': 'food',
    'bakso': 'food',
    'warung': 'food',
    'bistro': 'food',
    'drink': 'food',
    'uber': 'transport',
    'grab': 'transport',
    'taxi': 'transport',
    'gojek': 'transport',
    'bus': 'transport',
    'train': 'transport',
    'mrt': 'transport',
    'flight': 'transport',
    'parking': 'transport',
    'fuel': 'transport',
    'transport': 'transport',
    'hotel': 'accommodation',
    'hostel': 'accommodation',
    'airbnb': 'accommodation',
    'stay': 'accommodation',
    'accommodation': 'accommodation',
    'cinema': 'entertainment',
    'movie': 'entertainment',
    'concert': 'entertainment',
    'karaoke': 'entertainment',
    'ticket': 'entertainment',
    'museum': 'entertainment',
    'gym': 'entertainment',
    'shop': 'shopping',
    'mall': 'shopping',
    'groceries': 'shopping',
    'supermarket': 'shopping',
    'electricity': 'utilities',
    'internet': 'utilities',
    'wifi': 'utilities',
    'subscription': 'utilities',
    'insurance': 'utilities',
  };

  for (final e in keywords.entries) {
    if (lower.contains(e.key)) return e.value;
  }
  return null;
}
