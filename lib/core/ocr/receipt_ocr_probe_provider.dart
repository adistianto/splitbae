import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/ocr/receipt_ocr_channel.dart';
import 'package:splitbae/core/ocr/receipt_ocr_probe_result.dart';

/// On-device receipt OCR readiness (warm early in [AdaptiveHomeScreen]).
final receiptOcrProbeProvider = FutureProvider<ReceiptOcrProbeResult>((ref) async {
  return ReceiptOcrChannel.probe();
});
