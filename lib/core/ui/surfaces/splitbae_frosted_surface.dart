import 'package:flutter/material.dart';
import 'package:splitbae/core/theme/splitbae_shell_tokens.dart';

/// Shell search / floating panel surface. **Apple** Liquid Glass refraction is
/// handled by [splitBaeAppleLiquidGlassViewport] at the shell level — this widget
/// applies only a tinted fill + border (no [BackdropFilter]).
class SplitBaeFrostedPanel extends StatelessWidget {
  const SplitBaeFrostedPanel({
    super.key,
    required this.borderRadius,
    required this.child,
    this.fallbackElevation = 6,
    this.tintAlphaOverride,
  });

  final BorderRadius borderRadius;
  final Widget child;
  final double fallbackElevation;
  final double? tintAlphaOverride;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<SplitBaeShellTokens>() ??
        SplitBaeShellTokens.android();
    if (!tokens.liquidGlassChrome) {
      return Material(
        elevation: fallbackElevation,
        borderRadius: borderRadius,
        color: cs.surface,
        shadowColor: Colors.black26,
        child: child,
      );
    }
    final a = tintAlphaOverride ?? tokens.chromeTintAlpha;
    return Material(
      color: cs.surface.withValues(alpha: a),
      elevation: fallbackElevation > 0 ? 2 : 0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: cs.outline.withValues(alpha: tokens.chromeBorderOpacity),
        ),
      ),
      child: child,
    );
  }
}
