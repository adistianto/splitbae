import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:splitbae/core/ocr/receipt_ocr_probe_result.dart';

/// Native on-device text recognition: ML Kit (Android) and Vision (iOS).
class ReceiptOcrChannel {
  ReceiptOcrChannel._();

  static const MethodChannel _channel = MethodChannel('splitbae/receipt_ocr');

  /// Android / iPhone / iPad only (native channel registered there).
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
        'Receipt OCR is only available on Android and iOS.',
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
        'Receipt OCR is only available on Android and iOS.',
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
