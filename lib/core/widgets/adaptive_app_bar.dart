import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splitbae/core/platform/host_platform.dart';

/// True when the shell should use Cupertino navigation chrome (iOS / macOS).
bool splitBaeUseCupertinoNavBar() => hostPlatformIsApple();

/// iOS top bar for [CupertinoPageScaffold] or Material [Scaffold.appBar].
ObstructingPreferredSizeWidget splitBaeCupertinoNavigationBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
}) {
  final theme = Theme.of(context);
  return CupertinoNavigationBar(
    middle: Text(title),
    backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.74),
    enableBackgroundFilterBlur: true,
    automaticBackgroundVisibility: true,
    border: Border(
      bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
    ),
    trailing: actions == null || actions.isEmpty
        ? null
        : Row(mainAxisSize: MainAxisSize.min, children: actions),
  );
}

/// App bar: [CupertinoNavigationBar] on iOS host, [AppBar] elsewhere.
PreferredSizeWidget splitBaeAdaptiveAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  bool centerTitle = true,
}) {
  if (splitBaeUseCupertinoNavBar()) {
    return splitBaeCupertinoNavigationBar(
      context: context,
      title: title,
      actions: actions,
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
  if (splitBaeUseCupertinoNavBar()) {
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
