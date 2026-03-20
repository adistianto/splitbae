import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formats [amount] in [currencyCode] using [locale] digit/symbol rules.
String formatCurrencyAmount({
  required double amount,
  required String currencyCode,
  required Locale locale,
}) {
  final tag = _intlLocaleTag(locale);
  try {
    return NumberFormat.simpleCurrency(
      name: currencyCode,
      locale: tag,
    ).format(amount);
  } catch (_) {
    return '$currencyCode ${amount.toStringAsFixed(2)}';
  }
}

String _intlLocaleTag(Locale locale) {
  if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
    return '${locale.languageCode}_${locale.countryCode}';
  }
  // Prefer a territory when missing so IDR/USD get sensible defaults.
  return switch (locale.languageCode) {
    'id' => 'id_ID',
    'en' => 'en_US',
    _ => locale.languageCode,
  };
}
