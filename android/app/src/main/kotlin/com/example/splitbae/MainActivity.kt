package com.example.splitbae

import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val textRecognizer =
        TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "splitbae/receipt_ocr",
        ).setMethodCallHandler { call, result ->
            if (call.method == "probe") {
                result.success(
                    mapOf(
                        "ready" to true,
                        "engine" to "mlkit_text_latin",
                        "onDevice" to true,
                        "detail" to "ok",
                    ),
                )
                return@setMethodCallHandler
            }
            if (call.method != "recognizeText") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.arguments as? String
            if (path == null) {
                result.error("bad_args", "Missing path", null)
                return@setMethodCallHandler
            }
            val file = File(path)
            if (!file.exists()) {
                result.error("io", "File not found", null)
                return@setMethodCallHandler
            }
            val image: InputImage =
                try {
                    InputImage.fromFilePath(this, file)
                } catch (e: Exception) {
                    result.error("io", e.message, null)
                    return@setMethodCallHandler
                }
            textRecognizer
                .process(image)
                .addOnSuccessListener { visionText ->
                    result.success(visionText.text)
                }.addOnFailureListener { e ->
                    result.error("mlkit", e.message, null)
                }
        }
    }
}
