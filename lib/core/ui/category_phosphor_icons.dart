import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Phosphor icons for [Transaction.category] / v0 category ids (Lucide parity).
IconData splitBaeCategoryPhosphorIcon(String category) {
  switch (category) {
    case 'food':
      return PhosphorIconsRegular.bowlFood;
    case 'transport':
      return PhosphorIconsRegular.car;
    case 'accommodation':
      return PhosphorIconsRegular.bed;
    case 'entertainment':
      return PhosphorIconsRegular.musicNote;
    case 'shopping':
      return PhosphorIconsRegular.shoppingBag;
    case 'utilities':
      return PhosphorIconsRegular.lightning;
    case 'settlement':
      return PhosphorIconsRegular.arrowsLeftRight;
    default:
      return PhosphorIconsRegular.receipt;
  }
}
