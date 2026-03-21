import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies a camera/gallery file into app documents so it survives restarts.
Future<String?> persistReceiptImageFromPath(String? sourcePath) async {
  if (sourcePath == null || sourcePath.isEmpty) return null;
  final src = File(sourcePath);
  if (!await src.exists()) return null;
  final dir = await getApplicationDocumentsDirectory();
  final receipts = Directory(p.join(dir.path, 'receipts'));
  if (!await receipts.exists()) {
    await receipts.create(recursive: true);
  }
  final ext = p.extension(src.path).toLowerCase();
  final safeExt = (ext == '.png' || ext == '.jpg' || ext == '.jpeg') ? ext : '.jpg';
  final destPath = p.join(receipts.path, '${const Uuid().v4()}$safeExt');
  await src.copy(destPath);
  return destPath;
}

Future<void> deleteReceiptImageFileIfExists(String? path) async {
  if (path == null || path.isEmpty) return;
  final f = File(path);
  if (await f.exists()) {
    await f.delete();
  }
}
