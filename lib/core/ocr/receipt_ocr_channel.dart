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

  /// `true` where the native `splitbae/receipt_ocr` channel is implemented.
  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
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
  ///
  /// Native may return a **String** (legacy) or a **Map** with `text` (full OCR
  /// text) and optional `lines` (bounding boxes for each line, normalized 0–1).
  static Future<String> recognizeText(String absoluteImagePath) async {
    if (!isSupported) {
      throw UnsupportedError(
        'Receipt OCR is not available on this platform.',
      );
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'recognizeText',
        absoluteImagePath,
      );
      return _extractTextFromOcrPayload(raw);
    } on PlatformException catch (e) {
      throw ReceiptOcrException(e.code, e.message ?? 'OCR failed');
    } on MissingPluginException {
      throw ReceiptOcrException(
        'missing_plugin',
        'Receipt OCR native implementation is missing.',
      );
    }
  }

  /// Structured OCR: full text plus optional line boxes (normalized top-left).
  static Future<ReceiptOcrNativeResult> recognizeTextStructured(
    String absoluteImagePath,
  ) async {
    if (!isSupported) {
      throw UnsupportedError(
        'Receipt OCR is not available on this platform.',
      );
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'recognizeText',
        absoluteImagePath,
      );
      return _parseStructuredOcrPayload(raw);
    } on PlatformException catch (e) {
      throw ReceiptOcrException(e.code, e.message ?? 'OCR failed');
    } on MissingPluginException {
      throw ReceiptOcrException(
        'missing_plugin',
        'Receipt OCR native implementation is missing.',
      );
    }
  }

  static String _extractTextFromOcrPayload(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      final text = raw['text'];
      if (text is String) return text;
    }
    return '';
  }

  static ReceiptOcrNativeResult _parseStructuredOcrPayload(dynamic raw) {
    if (raw == null) {
      return const ReceiptOcrNativeResult(text: '', lines: []);
    }
    if (raw is String) {
      return ReceiptOcrNativeResult(text: raw, lines: const []);
    }
    if (raw is Map) {
      final text = raw['text'];
      final textStr = text is String ? text : '';
      final linesRaw = raw['lines'];
      final lines = <ReceiptOcrTextLine>[];
      if (linesRaw is List) {
        for (final e in linesRaw) {
          if (e is! Map) continue;
          final m = Map<Object?, Object?>.from(e);
          final t = m['text'];
          if (t is! String || t.isEmpty) continue;
          double? d(String k) {
            final v = m[k];
            if (v is num) return v.toDouble();
            return null;
          }

          lines.add(
            ReceiptOcrTextLine(
              text: t,
              left: d('left'),
              top: d('top'),
              width: d('width'),
              height: d('height'),
            ),
          );
        }
      }
      return ReceiptOcrNativeResult(text: textStr, lines: lines);
    }
    return const ReceiptOcrNativeResult(text: '', lines: []);
  }
}

/// One OCR text line from native (optional normalized bounds).
class ReceiptOcrTextLine {
  const ReceiptOcrTextLine({
    required this.text,
    this.left,
    this.top,
    this.width,
    this.height,
  });

  final String text;
  final double? left;
  final double? top;
  final double? width;
  final double? height;
}

class ReceiptOcrNativeResult {
  const ReceiptOcrNativeResult({
    required this.text,
    required this.lines,
  });

  final String text;
  final List<ReceiptOcrTextLine> lines;
}

class ReceiptOcrException implements Exception {
  ReceiptOcrException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ReceiptOcrException($code): $message';
}
