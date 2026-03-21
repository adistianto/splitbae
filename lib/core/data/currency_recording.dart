/// Picks the ISO 4217 code with the largest total minor amount (for multi-currency
/// drafts). Used for [Transactions.currencyCode] (recording currency for the bill).
String pickDominantCurrencyCode(
  Map<String, int> totalsMinorByCurrency, {
  required String fallbackWhenEmpty,
}) {
  if (totalsMinorByCurrency.isEmpty) return fallbackWhenEmpty;
  var best = '';
  var bestAmt = -1;
  for (final e in totalsMinorByCurrency.entries) {
    if (e.value > bestAmt) {
      bestAmt = e.value;
      best = e.key;
    }
  }
  return best.isNotEmpty ? best : fallbackWhenEmpty;
}
