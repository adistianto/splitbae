import AppKit
import Cocoa
import FlutterMacOS
import ImageIO
import Vision

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// Called from `MainFlutterWindow` once the `FlutterViewController` exists.
  static func registerReceiptOcrChannel(controller: FlutterViewController) {
    ReceiptOcrChannelPlugin.register(binaryMessenger: controller.engine.binaryMessenger)
  }
}

enum ReceiptOcrChannelPlugin {
  static func register(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "splitbae/receipt_ocr",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "probe" {
        result([
          "ready": true,
          "engine": "vision",
          "onDevice": true,
          "detail": "ok",
        ])
        return
      }
      guard call.method == "recognizeText" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let path = call.arguments as? String else {
        result(FlutterError(code: "bad_args", message: "Missing path", details: nil))
        return
      }

      let url = URL(fileURLWithPath: path)
      guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
      else {
        result(FlutterError(code: "image", message: "Could not load image", details: nil))
        return
      }

      let request = VNRecognizeTextRequest { request, error in
        DispatchQueue.main.async {
          if let error = error {
            result(
              FlutterError(
                code: "vision", message: error.localizedDescription, details: nil))
            return
          }
          guard let observations = request.results as? [VNRecognizedTextObservation] else {
            result(["text": "", "lines": []] as [String: Any])
            return
          }
          let sorted = observations.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
          var linesOut: [[String: Any]] = []
          var joined: [String] = []
          for obs in sorted {
            guard let line = obs.topCandidates(1).first else { continue }
            joined.append(line.string)
            let b = obs.boundingBox
            let left = b.origin.x
            let topFromTop = 1.0 - b.origin.y - b.size.height
            linesOut.append([
              "text": line.string,
              "left": left,
              "top": topFromTop,
              "width": b.size.width,
              "height": b.size.height,
            ])
          }
          let fullText = joined.joined(separator: "\n")
          result([
            "text": fullText,
            "lines": linesOut,
          ] as [String: Any])
        }
      }
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      if #available(macOS 13.0, *) {
        request.revision = VNRecognizeTextRequestRevision3
      }

      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try handler.perform([request])
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "vision", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }
}
