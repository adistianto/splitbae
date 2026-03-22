import 'package:flutter/material.dart';
import 'package:splitbae/core/theme/splitbae_shell_tokens.dart';
import 'package:splitbae/core/ui/surfaces/splitbae_frosted_surface.dart';

/// Floating search bar for the home shell — **glass** on Apple, **Material**
/// elevation on Android (tokens decide).
class SplitBaeShellSearchField extends StatelessWidget {
  const SplitBaeShellSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<SplitBaeShellTokens>() ??
        SplitBaeShellTokens.android();

    final field = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search, size: 22),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: tokens.liquidGlassChrome
                    ? Colors.transparent
                    : cs.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: tokens.liquidGlassChrome
                    ? Colors.transparent
                    : cs.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: cs.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            filled: tokens.liquidGlassChrome,
            fillColor: tokens.liquidGlassChrome
                ? cs.surface.withValues(alpha: 0.01)
                : null,
          ),
        );
      },
    );

    return SplitBaeFrostedPanel(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      fallbackElevation: tokens.searchFieldMaterialElevation,
      child: field,
    );
  }
}
