import 'dart:io' show Platform;

bool get isIOSHost => Platform.isIOS;

bool get isMacOSHost => Platform.isMacOS;

bool get isAppleHost => Platform.isIOS || Platform.isMacOS;
