import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/theme/splitbae_v0_ui_contract.dart';

/// Floating circular control (v0 top-right search / profile).
///
/// On **Apple** hosts, uses a light backdrop blur like v0’s `backdrop-blur-xl`;
/// on **Android**, uses elevated Material surface (M3 expressive bar affordance).
class SplitBaeV0CircleIconButton extends StatelessWidget {
  const SplitBaeV0CircleIconButton({
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
    final size = SplitBaeV0Layout.shellFloatingIconSize;
    final apple = hostPlatformIsApple();

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

    final Widget body = apple
        ? ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: SplitBaeV0Layout.shellChromeBlurSigma,
                sigmaY: SplitBaeV0Layout.shellChromeBlurSigma,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surface.withValues(alpha: 0.72),
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.35),
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
          )
        : Material(
            color: cs.surface.withValues(alpha: 0.95),
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: Colors.black26,
            child: inner,
          );

    return Semantics(
      button: true,
      label: semanticLabel,
      child: body,
    );
  }
}
