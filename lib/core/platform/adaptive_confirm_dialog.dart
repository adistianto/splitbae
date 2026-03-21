import 'package:flutter/material.dart';

/// Material alert on Android/desktop; Cupertino-style sheet on iOS (and iPadOS).
Future<bool?> showAdaptiveConfirmDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  required String cancelLabel,
  required String confirmLabel,
  bool confirmIsDestructive = false,
}) {
  final theme = Theme.of(context);
  return showAdaptiveDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog.adaptive(
        title: title,
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            style: confirmIsDestructive
                ? TextButton.styleFrom(foregroundColor: theme.colorScheme.error)
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
