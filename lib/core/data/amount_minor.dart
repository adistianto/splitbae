/// Maps a decimal UI amount to integer minor units for [currencyCode].
/// IDR: 1 minor = 1 Rp. USD/EUR: minor = cents/centimes (10^-2).
int amountToMinorUnits(double amount, String currencyCode) {
  final c = currencyCode.toUpperCase();
  if (c == 'IDR' || c == 'JPY' || c == 'KRW') {
    return amount.round();
  }
  return (amount * 100).round();
}

double minorUnitsToAmount(int minor, String currencyCode) {
  final c = currencyCode.toUpperCase();
  if (c == 'IDR' || c == 'JPY' || c == 'KRW') {
    return minor.toDouble();
  }
  return minor / 100.0;
}

/// Text for add/edit amount fields (integer currencies vs two decimals).
String amountToInputText(double amount, String currencyCode) {
  final c = currencyCode.toUpperCase();
  if (c == 'IDR' || c == 'JPY' || c == 'KRW') {
    return amount.round().toString();
  }
  return amount.toStringAsFixed(2);
}
