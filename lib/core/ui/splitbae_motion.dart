import 'package:flutter/widgets.dart';

/// Whether custom animations should run (respects system “reduce motion”).
bool splitBaeAnimationsEnabled(BuildContext context) {
  return !MediaQuery.disableAnimationsOf(context);
}

/// Use for [AnimatedRotation], [AnimatedContainer], etc.
Duration splitBaeAnimationDuration(BuildContext context, Duration normal) {
  return splitBaeAnimationsEnabled(context) ? normal : Duration.zero;
}

Curve splitBaeAnimationCurve(BuildContext context) {
  return splitBaeAnimationsEnabled(context) ? Curves.easeOutCubic : Curves.linear;
}
