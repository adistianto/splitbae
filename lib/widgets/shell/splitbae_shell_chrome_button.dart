import 'package:flutter/material.dart';
import 'package:splitbae/core/theme/splitbae_shell_tokens.dart';
import 'package:splitbae/core/theme/splitbae_v0_ui_contract.dart';

/// Floating circular shell control (search / profile) — **v0 layout**:
/// **Material** on Android; on Apple, tinted surface without [BackdropFilter]
/// (shell Liquid Glass is applied to tab bar / rail only).
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
    if (tokens.liquidGlassChrome) {
      body = Material(
        color: cs.surface.withValues(alpha: tokens.chromeTintAlpha),
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black26,
        child: inner,
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
