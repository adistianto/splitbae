import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../prefs_keys.dart';

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

/// Reads a **cached** Material You availability when fresh enough, otherwise
/// [probeDynamicColorAvailable] once and stores the result.
///
/// **TTL**: cached `true` is trusted longer (palette support rarely disappears);
/// cached `false` is refreshed sooner so an OS upgrade to Android 12+ is picked up.
Future<bool> resolveDynamicColorSupported() async {
  if (defaultTargetPlatform != TargetPlatform.android) return false;

  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now().millisecondsSinceEpoch;
  final at = prefs.getInt(kDynamicColorSupportedCachedAtMsKey);
  final cached = prefs.getBool(kDynamicColorSupportedCachedKey);

  if (cached != null && at != null) {
    final ageMs = now - at;
    final ttlMs = cached
        ? const Duration(days: 30).inMilliseconds
        : const Duration(days: 5).inMilliseconds;
    if (ageMs >= 0 && ageMs < ttlMs) {
      return cached;
    }
  }

  final live = await probeDynamicColorAvailable();
  await prefs.setBool(kDynamicColorSupportedCachedKey, live);
  await prefs.setInt(kDynamicColorSupportedCachedAtMsKey, now);
  return live;
}

/// Overridden from [main] after [resolveDynamicColorSupported] (default: unsupported).
final dynamicColorSupportedProvider = Provider<bool>((ref) => false);
