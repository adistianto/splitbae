import 'package:splitbae/src/rust/api/simple.dart' as rust;

/// Thin FRB wrappers — rules live in `rust/src/api/simple.rs`, not here.

int amountToMinorUnits(double amount, String currencyCode) {
  final v = rust.amountToMinorUnits(amount: amount, currencyCode: currencyCode);
  return int.parse(v.toString());
}

double minorUnitsToAmount(int minor, String currencyCode) {
  return rust.minorUnitsToAmount(minor: minor, currencyCode: currencyCode);
}

String amountToInputText(double amount, String currencyCode) {
  return rust.amountToInputText(amount: amount, currencyCode: currencyCode);
}
