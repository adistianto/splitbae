import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// True when the shell should use [CupertinoNavigationBar] (iOS-style chrome).
bool splitBaeUseCupertinoNavBar(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.iOS;
}

/// App bar that maps to [CupertinoNavigationBar] on iOS and [AppBar] elsewhere.
PreferredSizeWidget splitBaeAdaptiveAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  bool centerTitle = true,
}) {
  final theme = Theme.of(context);
  if (splitBaeUseCupertinoNavBar(context)) {
    return CupertinoNavigationBar(
      middle: Text(title),
      backgroundColor: theme.colorScheme.surface,
      border: Border(
        bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      trailing: actions == null || actions.isEmpty
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: actions),
    );
  }
  return AppBar(title: Text(title), centerTitle: centerTitle, actions: actions);
}

/// Toolbar icon: [CupertinoButton] on iOS, [IconButton] on other platforms.
Widget splitBaeAdaptiveToolbarIcon({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onPressed,
  String? tooltip,
}) {
  if (splitBaeUseCupertinoNavBar(context)) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Icon(icon, size: 26),
    );
  }
  return IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon));
}

/// First character for avatars (first Unicode scalar; good for typical names).
String splitBaeInitialGrapheme(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  final it = t.runes.iterator;
  return it.moveNext() ? String.fromCharCode(it.current).toUpperCase() : '?';
}
