import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:splitbae/core/theme/splitbae_shell_tokens.dart';

/// Frosted **Liquid Glass** panel: blur + translucent fill + optional border.
///
/// When [SplitBaeShellTokens.liquidGlassChrome] is false, builds a solid
/// [Material] with [fallbackElevation] instead (Android expressive).
class SplitBaeFrostedPanel extends StatelessWidget {
  const SplitBaeFrostedPanel({
    super.key,
    required this.borderRadius,
    required this.child,
    this.fallbackElevation = 6,
    this.blurSigmaOverride,
    this.tintAlphaOverride,
  });

  final BorderRadius borderRadius;
  final Widget child;
  final double fallbackElevation;
  final double? blurSigmaOverride;
  final double? tintAlphaOverride;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<SplitBaeShellTokens>() ??
        SplitBaeShellTokens.android();
    if (!tokens.liquidGlassChrome || tokens.chromeBlurSigma <= 0) {
      return Material(
        elevation: fallbackElevation,
        borderRadius: borderRadius,
        color: cs.surface,
        shadowColor: Colors.black26,
        child: child,
      );
    }
    final sigma = blurSigmaOverride ?? tokens.chromeBlurSigma;
    final a = tintAlphaOverride ?? tokens.chromeTintAlpha;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: cs.surface.withValues(alpha: a),
            border: Border.all(
              color: cs.outline.withValues(alpha: tokens.chromeBorderOpacity),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
