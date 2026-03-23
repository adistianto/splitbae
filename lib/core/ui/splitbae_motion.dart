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

/// Standard “v0 web-like” mount timing.
const Duration splitBaeStandardMountDuration = Duration(milliseconds: 300);

/// Standard stagger step for list reveals.
const Duration splitBaeStandardStaggerStep = Duration(milliseconds: 50);

/// Duration for mount/fade/slide entrances that should feel snappy.
Duration splitBaeMountDuration(BuildContext context) {
  return splitBaeAnimationDuration(context, splitBaeStandardMountDuration);
}

/// Delay for per-item reveals. Returns `Duration.zero` when animations are disabled.
Duration splitBaeStaggerDelay(BuildContext context, int index) {
  if (!splitBaeAnimationsEnabled(context)) return Duration.zero;
  return Duration(
    milliseconds: index * splitBaeStandardStaggerStep.inMilliseconds,
  );
}

/// Curve for mount/fade/slide entrances.
Curve splitBaeMountCurve(BuildContext context) {
  return splitBaeAnimationCurve(context);
}
