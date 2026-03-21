#ifndef RUNNER_RECEIPT_OCR_WIN_H_
#define RUNNER_RECEIPT_OCR_WIN_H_

namespace flutter {
class FlutterEngine;
}

/// Registers `splitbae/receipt_ocr` on the Flutter engine (WinRT OCR path).
void RegisterReceiptOcrChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_RECEIPT_OCR_WIN_H_
