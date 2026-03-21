/// Result of [ReceiptOcrChannel.probe] — on-device engine readiness (no image).
class ReceiptOcrProbeResult {
  const ReceiptOcrProbeResult({
    required this.ready,
    required this.engineId,
    this.onDevice = true,
    this.detail,
  });

  final bool ready;

  /// e.g. `mlkit_text_latin`, `vision`, `none`.
  final String engineId;

  /// All current integrations run on-device (no cloud OCR in this path).
  final bool onDevice;

  final String? detail;

  static ReceiptOcrProbeResult unsupported() => const ReceiptOcrProbeResult(
        ready: false,
        engineId: 'none',
        onDevice: true,
        detail: 'platform_unsupported',
      );

  static ReceiptOcrProbeResult missingPlugin() => const ReceiptOcrProbeResult(
        ready: false,
        engineId: 'none',
        onDevice: true,
        detail: 'missing_plugin',
      );

  static ReceiptOcrProbeResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const ReceiptOcrProbeResult(
        ready: false,
        engineId: 'none',
        detail: 'bad_response',
      );
    }
    final ready = map['ready'] == true;
    final engine = map['engine'] as String? ?? 'unknown';
    final onDevice = map['onDevice'] != false;
    final detail = map['detail'] as String?;
    return ReceiptOcrProbeResult(
      ready: ready,
      engineId: engine,
      onDevice: onDevice,
      detail: detail,
    );
  }
}
