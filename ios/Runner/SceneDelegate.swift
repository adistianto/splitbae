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
            result("")
            return
          }
          // Vision uses bottom-left origin; top-to-bottom reading order ≈ descending maxY.
          let sorted = observations.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
          let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
          result(lines.joined(separator: "\n"))
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
