import Flutter
import UIKit
import Vision

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    ReceiptOcrChannelRegistration.registerIfNeeded(scene: scene)
  }
}

enum ReceiptOcrChannelRegistration {
  private static var didRegister = false

  static func registerIfNeeded(scene: UIScene) {
    guard !didRegister,
      let windowScene = scene as? UIWindowScene,
      let root = windowScene.windows.first?.rootViewController as? FlutterViewController
    else {
      return
    }
    ReceiptOcrChannelPlugin.register(binaryMessenger: root.binaryMessenger)
    didRegister = true
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
      guard let uiImage = UIImage(contentsOfFile: path), let cgImage = uiImage.cgImage else {
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
          // Vision uses bottom-left origin; sort top-to-bottom by maxY.
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
      if #available(iOS 16.0, *) {
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
