import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:splitbae/core/ocr/receipt_ocr_probe_result.dart';

/// Native **on-device** text recognition via `splitbae/receipt_ocr`:
/// **ML Kit** (Android), **Vision** (iOS + macOS), **WinRT** `Windows.Media.Ocr`
/// (Windows). Parsing helpers in Dart run after native text is returned.
///
/// **Linux / web:** not wired. Linux typically needs Tesseract or a similar engine.
class ReceiptOcrChannel {
  ReceiptOcrChannel._();

  static const MethodChannel _channel = MethodChannel('splitbae/receipt_ocr');

  /// `true` only on **Android** and **iOS** where the native channel exists.
  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Lightweight check that the native OCR stack is reachable (no image).
  static Future<ReceiptOcrProbeResult> probe() async {
    if (!isSupported) return ReceiptOcrProbeResult.unsupported();
    try {
      final raw = await _channel.invokeMethod<dynamic>('probe');
      if (raw is Map) {
        return ReceiptOcrProbeResult.fromMap(Map<Object?, Object?>.from(raw));
      }
      return const ReceiptOcrProbeResult(
        ready: false,
        engineId: 'none',
        detail: 'bad_response',
      );
    } on MissingPluginException {
      return ReceiptOcrProbeResult.missingPlugin();
    } catch (_) {
      return const ReceiptOcrProbeResult(
        ready: false,
        engineId: 'none',
        detail: 'probe_failed',
      );
    }
  }

  /// Returns plain text from the image at [absoluteImagePath], or empty string.
  static Future<String> recognizeText(String absoluteImagePath) async {
    if (!isSupported) {
      throw UnsupportedError(
        'Receipt OCR is not available on this platform.',
      );
    }
    try {
      final text = await _channel.invokeMethod<String>(
        'recognizeText',
        absoluteImagePath,
      );
      return text ?? '';
    } on PlatformException catch (e) {
      throw ReceiptOcrException(e.code, e.message ?? 'OCR failed');
    } on MissingPluginException {
      throw ReceiptOcrException(
        'missing_plugin',
        'Receipt OCR native implementation is missing.',
      );
    }
  }
}

class ReceiptOcrException implements Exception {
  ReceiptOcrException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ReceiptOcrException($code): $message';
}
