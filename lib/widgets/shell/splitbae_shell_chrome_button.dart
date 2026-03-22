import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:splitbae/core/theme/splitbae_shell_tokens.dart';
import 'package:splitbae/core/theme/splitbae_v0_ui_contract.dart';

/// Floating circular shell control (search / profile) — **v0 layout**, native
/// execution: **Material elevation** on Android, **Liquid Glass** on Apple.
class SplitBaeShellChromeIconButton extends StatelessWidget {
  const SplitBaeShellChromeIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<SplitBaeShellTokens>() ??
        SplitBaeShellTokens.android();
    final size = SplitBaeV0Layout.shellFloatingIconSize;

    final inner = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 22, color: cs.onSurface),
        ),
      ),
    );

    final Widget body;
    if (tokens.liquidGlassChrome && tokens.chromeBlurSigma > 0) {
      body = ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: tokens.chromeBlurSigma,
            sigmaY: tokens.chromeBlurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surface.withValues(alpha: tokens.chromeTintAlpha),
              border: Border.all(
                color: cs.outline.withValues(alpha: tokens.chromeBorderOpacity),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: inner,
          ),
        ),
      );
    } else {
      body = Material(
        color: cs.surface.withValues(alpha: tokens.chromeTintAlpha.clamp(0.0, 1.0)),
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black26,
        child: inner,
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: body,
    );
  }
}
