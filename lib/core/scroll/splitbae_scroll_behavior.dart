import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Mouse / trackpad drag scrolling on desktop and web.
class SplitBaeScrollBehavior extends MaterialScrollBehavior {
  const SplitBaeScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
