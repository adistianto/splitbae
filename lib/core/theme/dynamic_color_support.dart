import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether Android exposed a wallpaper [CorePalette] for Material You.
/// Completes `false` on non-Android, pre–Android 12, or when the plugin returns null.
Future<bool> probeDynamicColorAvailable() async {
  if (defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    final core = await DynamicColorPlugin.getCorePalette();
    return core != null;
  } catch (_) {
    return false;
  }
}

/// Set from [main] after [probeDynamicColorAvailable] (default here is conservative).
final dynamicColorSupportedProvider = Provider<bool>((ref) => false);
