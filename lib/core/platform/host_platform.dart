import 'host_platform_stub.dart'
    if (dart.library.io) 'host_platform_io.dart'
    as impl;

/// Whether the **host OS** is iOS (device or Simulator).
///
/// On web this is always false. Uses `Platform.isIOS` when `dart:io` exists.
bool hostPlatformIsIOS() => impl.isIOSHost;

/// Whether the **host OS** is macOS (desktop Flutter).
bool hostPlatformIsMacOS() => impl.isMacOSHost;

/// iOS or macOS — shared Cupertino chrome and [CupertinoTheme] bridge.
bool hostPlatformIsApple() => impl.isAppleHost;
