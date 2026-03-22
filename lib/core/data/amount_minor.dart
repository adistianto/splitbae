import 'package:flutter/foundation.dart';
import 'package:splitbae/src/rust/api/simple.dart' as rust;

/// Thin FRB wrappers — rules live in `rust/src/api/simple.rs`, not here.

int Function(double amount, String currencyCode)? _debugAmountToMinorOverride;

double Function(int minor, String currencyCode)? _debugMinorToAmountOverride;

/// VM `flutter test` only: bypasses Rust when native `rust_lib` is not loaded.
/// Must mirror [rust.amountToMinorUnits] for the currencies you exercise.
@visibleForTesting
void debugSetAmountMinorOverridesForTest({
  int Function(double amount, String currencyCode)? amountToMinor,
  double Function(int minor, String currencyCode)? minorToAmount,
}) {
  _debugAmountToMinorOverride = amountToMinor;
  _debugMinorToAmountOverride = minorToAmount;
}

int amountToMinorUnits(double amount, String currencyCode) {
  final o = _debugAmountToMinorOverride;
  if (o != null) return o(amount, currencyCode);
  final v = rust.amountToMinorUnits(amount: amount, currencyCode: currencyCode);
  return int.parse(v.toString());
}

double minorUnitsToAmount(int minor, String currencyCode) {
  final o = _debugMinorToAmountOverride;
  if (o != null) return o(minor, currencyCode);
  return rust.minorUnitsToAmount(minor: minor, currencyCode: currencyCode);
}

String amountToInputText(double amount, String currencyCode) {
  return rust.amountToInputText(amount: amount, currencyCode: currencyCode);
}
