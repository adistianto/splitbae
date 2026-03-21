import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:splitbae/l10n/app_localizations.dart';

/// Ensures camera (all mobile) and photo library (iOS only) permission before
/// [ImagePicker.pickImage]. Android gallery uses the system picker without a
/// separate preflight in most cases.
Future<bool> ensureReceiptImageSourcePermission(
  BuildContext context,
  AppLocalizations l10n,
  ImageSource source,
) async {
  if (kIsWeb) return true;
  if (source == ImageSource.camera) {
    return _ensurePermission(
      context,
      l10n,
      Permission.camera,
      deniedSnack: l10n.scanReceiptPermissionCameraDenied,
      blockedTitle: l10n.scanReceiptPermissionCameraBlockedTitle,
      blockedBody: l10n.scanReceiptPermissionCameraBlockedBody,
    );
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return _ensurePermission(
      context,
      l10n,
      Permission.photos,
      deniedSnack: l10n.scanReceiptPermissionPhotosDenied,
      blockedTitle: l10n.scanReceiptPermissionPhotosBlockedTitle,
      blockedBody: l10n.scanReceiptPermissionPhotosBlockedBody,
    );
  }
  return true;
}

Future<bool> _ensurePermission(
  BuildContext context,
  AppLocalizations l10n,
  Permission permission, {
  required String deniedSnack,
  required String blockedTitle,
  required String blockedBody,
}) async {
  var status = await permission.status;
  if (status.isGranted || status.isLimited) return true;
  if (status.isPermanentlyDenied) {
    if (!context.mounted) return false;
    await _showOpenSettingsDialog(
      context,
      l10n: l10n,
      title: blockedTitle,
      body: blockedBody,
    );
    return false;
  }

  status = await permission.request();
  if (status.isGranted || status.isLimited) return true;
  if (!context.mounted) return false;
  if (status.isPermanentlyDenied) {
    await _showOpenSettingsDialog(
      context,
      l10n: l10n,
      title: blockedTitle,
      body: blockedBody,
    );
    return false;
  }

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(deniedSnack)));
  return false;
}

Future<void> _showOpenSettingsDialog(
  BuildContext context, {
  required AppLocalizations l10n,
  required String title,
  required String body,
}) async {
  final go = await showAdaptiveDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.scanReceiptPermissionOpenSettings),
        ),
      ],
    ),
  );
  if (go == true) {
    await openAppSettings();
  }
}
