import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:flutter/material.dart';

/// Material 3 window size classes (width in logical pixels).
/// See: https://m3.material.io/foundations/layout/applying-layout/window-size-classes
abstract final class AppBreakpoints {
  static const double compactMax = 599;
  static const double mediumMax = 839;

  /// From here up: navigation rail, richer layouts.
  static const double expandedMin = 840;

  /// Two-pane bill + split layout.
  static const double twoPaneMin = 1100;

  /// Use extended labels on [NavigationRail].
  static const double railExtendedLabelsMin = 1200;
}

enum AppWindowClass {
  /// Phone portrait, small fold outer.
  compact,

  /// Tablet portrait, large phone landscape.
  medium,

  /// Tablet landscape, desktop, fold inner.
  expanded,
}

AppWindowClass windowClassForWidth(double width) {
  if (width <= AppBreakpoints.compactMax) return AppWindowClass.compact;
  if (width <= AppBreakpoints.mediumMax) return AppWindowClass.medium;
  return AppWindowClass.expanded;
}

/// Extra inset so lists avoid fold hinges and cutouts (best-effort).
EdgeInsets hingeAwarePadding(BuildContext context) {
  var add = EdgeInsets.zero;
  try {
    final size = MediaQuery.sizeOf(context);
    for (final DisplayFeature f in MediaQuery.displayFeaturesOf(context)) {
      if (f.type != DisplayFeatureType.fold &&
          f.type != DisplayFeatureType.hinge) {
        continue;
      }
      final b = f.bounds;
      if (b.width <= 0 || b.height <= 0) continue;
      // Vertical seam in the middle: pad both sides slightly.
      if (b.width < size.width * 0.2 && b.height > size.height * 0.5) {
        add += EdgeInsets.symmetric(horizontal: (b.width / 2).clamp(4.0, 16.0));
      }
    }
  } catch (_) {
    // Tests / platforms without display feature API.
  }
  return add;
}
