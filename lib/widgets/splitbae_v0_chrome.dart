import 'package:flutter/material.dart';

/// Floating circular control (v0 top-right search / profile).
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
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: cs.surface.withValues(alpha: 0.95),
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}
