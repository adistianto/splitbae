import 'package:flutter/widgets.dart';

/// Horizontal gutter for page content: grows slightly with text-size accessibility
/// so line length stays comfortable without fully mirroring font scale (avoids
/// layout explosion on extreme settings).
double splitBaePageHorizontalPadding(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(16) / 16.0;
  return (16 * scale.clamp(0.9, 1.4)).clamp(12.0, 32.0);
}
