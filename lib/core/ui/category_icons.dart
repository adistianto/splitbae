import 'package:flutter/material.dart';

/// v0-style category ids on [Transaction.category].
IconData splitBaeCategoryIcon(String category) {
  switch (category) {
    case 'food':
      return Icons.restaurant;
    case 'transport':
      return Icons.directions_car;
    case 'accommodation':
      return Icons.hotel;
    case 'entertainment':
      return Icons.music_note;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'utilities':
      return Icons.bolt_outlined;
    case 'settlement':
      return Icons.swap_horiz;
    default:
      return Icons.receipt_long;
  }
}
