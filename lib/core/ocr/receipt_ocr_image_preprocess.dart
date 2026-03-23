import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Preprocesses an image file into an OCR-friendly temp file for the native
/// `splitbae/receipt_ocr` pipeline.
///
/// MVP goals:
/// - Fix EXIF orientation issues by decoding and re-encoding rotated output.
/// - Cap the largest edge so OCR input is not excessively large.
///
/// Returns `null` when preprocessing fails; callers should fall back to the
/// original [imagePath].
Future<String?> preprocessReceiptOcrInputImage(
  String imagePath, {
  Uint8List? bytes,
  int maxEdgePx = 2400,
  int jpgQuality = 85,
  num? contrast,
  num? brightness,
}) async {
  final src = File(imagePath);
  if (!await src.exists()) return null;

  final data = bytes ?? await src.readAsBytes();
  if (data.isEmpty) return null;

  final decoded = img.decodeImage(data);
  if (decoded == null) return null;

  // Apply EXIF orientation when available (common for photos from camera rolls).
  final orientation = _tryReadExifOrientation(data);
  var normalized = decoded;
  if (orientation != null && orientation != 1) {
    normalized = _applyExifOrientation(normalized, orientation);
  }

  // Cap the max edge only when the image is too large.
  if (maxEdgePx > 0) {
    final maxDim = mathMax(normalized.width, normalized.height);
    if (maxDim > maxEdgePx) {
      final scale = maxEdgePx / maxDim;
      final w = (normalized.width * scale).round();
      final h = (normalized.height * scale).round();
      normalized = img.copyResize(
        normalized,
        width: w,
        height: h,
        interpolation: img.Interpolation.linear,
      );
    }
  }

  // Optional photo enhancement variant used for OCR retries.
  if (contrast != null || brightness != null) {
    normalized = img.adjustColor(
      normalized,
      contrast: contrast,
      brightness: brightness,
    );
  }

  final encoded = img.encodeJpg(normalized, quality: jpgQuality);
  if (encoded.isEmpty) return null;

  final dir = await getTemporaryDirectory();
  final outPath = p.join(
    dir.path,
    'receipt_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await File(outPath).writeAsBytes(encoded, flush: true);
  return outPath;
}

int? _tryReadExifOrientation(Uint8List bytes) {
  try {
    // EXIF orientation is primarily relevant for JPEG camera photos.
    final exif = img.decodeJpgExif(bytes);
    return exif?.imageIfd.orientation;
  } catch (_) {
    return null;
  }
}

img.Image _applyExifOrientation(img.Image src, int orientation) {
  // EXIF orientation mapping:
  // 1 = normal
  // 2 = horizontal flip
  // 3 = rotate 180
  // 4 = vertical flip
  // 5 = transpose
  // 6 = rotate 90 CW
  // 7 = transverse
  // 8 = rotate 270 CW
  switch (orientation) {
    case 1:
      return src;
    case 2:
      return img.flipHorizontal(src);
    case 3:
      return img.copyRotate(src, angle: 180);
    case 4:
      return img.flipVertical(src);
    case 5: // transpose
      return img.copyRotate(img.flipHorizontal(src), angle: 270);
    case 6: // rotate 90 CW
      return img.copyRotate(src, angle: 90);
    case 7: // transverse
      return img.copyRotate(img.flipHorizontal(src), angle: 90);
    case 8: // rotate 270 CW
      return img.copyRotate(src, angle: 270);
    default:
      return src;
  }
}

int mathMax(int a, int b) => a >= b ? a : b;

