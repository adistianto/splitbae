// Receipt OCR for Windows:
// - Prefer WinRT `Microsoft.Windows.AI.Imaging.TextRecognizer` when the feature
//   reports Ready (NPU / Copilot+ class hardware per Microsoft; see
//   `TextRecognizer::GetReadyState()` and `AIFeatureReadyState`).
// - Fall back to `Windows.Media.Ocr` (broad CPU support).
//
// AI headers ship with the Windows App SDK NuGet. CMake enables
// `SPLITBAE_WASDK_AI_OCR` when it finds `winrt/Microsoft.Windows.AI.Imaging.h`
// (auto-detect under %USERPROFILE%\.nuget\packages\microsoft.windowsappsdk\*
// or set SPLITBAE_WINDOWS_APP_SDK_INCLUDE).
//
// Unpackaged apps may need the Windows App Runtime + optional bootstrap; if AI
// calls fail at runtime, we still fall back to Media OCR.
//
// This file opts into C++ exceptions for cppwinrt (`get()` on async), unlike
// the rest of the runner which disables them.

#include "receipt_ocr_win.h"

#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <memory>
#include <optional>
#include <sstream>
#include <string>

#include <windows.h>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Globalization.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/base.h>

#if defined(SPLITBAE_WASDK_AI_OCR)
#include <winrt/Microsoft.Graphics.Imaging.h>
#include <winrt/Microsoft.Windows.AI.Imaging.h>
#include <winrt/Microsoft.Windows.AI.h>
#endif

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

std::wstring Utf8PathToWide(const std::string& utf8) {
  if (utf8.empty()) {
    return L"";
  }
  int size = ::MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  if (size <= 0) {
    return L"";
  }
  std::wstring wide(static_cast<size_t>(size - 1), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, wide.data(), size);
  return wide;
}

winrt::Windows::Graphics::Imaging::SoftwareBitmap LoadSoftwareBitmapFromWidePath(
    const std::wstring& wide_path) {
  using namespace winrt::Windows::Graphics::Imaging;
  using namespace winrt::Windows::Storage;

  winrt::Windows::Storage::StorageFile file =
      winrt::Windows::Storage::StorageFile::GetFileFromPathAsync(wide_path)
          .get();
  winrt::Windows::Storage::Streams::IRandomAccessStream stream =
      file.OpenAsync(winrt::Windows::Storage::FileAccessMode::Read).get();
  BitmapDecoder decoder = BitmapDecoder::CreateAsync(stream).get();
  return decoder.GetSoftwareBitmapAsync().get();
}

#if defined(SPLITBAE_WASDK_AI_OCR)

/// Returns joined text if AI imaging OCR succeeds; nullopt to use Media OCR.
std::optional<winrt::hstring> TryRecognizeWithAiImaging(
    const winrt::Windows::Graphics::Imaging::SoftwareBitmap& bitmap) {
  using winrt::Microsoft::Graphics::Imaging::ImageBuffer;
  using winrt::Microsoft::Windows::AI::AIFeatureReadyState;
  using winrt::Microsoft::Windows::AI::Imaging::TextRecognizer;

  AIFeatureReadyState state = TextRecognizer::GetReadyState();
  if (state == AIFeatureReadyState::NotSupportedOnCurrentSystem) {
    return std::nullopt;
  }
  if (state == AIFeatureReadyState::DisabledByUser) {
    return std::nullopt;
  }
  if (state == AIFeatureReadyState::NotReady) {
    TextRecognizer::EnsureReadyAsync().get();
    state = TextRecognizer::GetReadyState();
    if (state != AIFeatureReadyState::Ready) {
      return std::nullopt;
    }
  }

  auto recognizer = TextRecognizer::CreateAsync().get();
  auto image_buffer = ImageBuffer::CreateForSoftwareBitmap(bitmap);
  auto recognized = recognizer.RecognizeTextFromImage(image_buffer);

  std::wstringstream out;
  for (const auto& line : recognized.Lines()) {
    out << std::wstring{line.Text()} << L'\n';
  }
  std::wstring text = out.str();
  if (!text.empty() && text.back() == L'\n') {
    text.pop_back();
  }
  return winrt::hstring{text};
}

#endif  // SPLITBAE_WASDK_AI_OCR

EncodableMap RecognizeWithMediaOcrMap(
    const winrt::Windows::Graphics::Imaging::SoftwareBitmap& bitmap) {
  using namespace winrt::Windows::Media::Ocr;

  OcrEngine engine = OcrEngine::TryCreateFromUserProfileLanguages();
  if (!engine) {
    engine = OcrEngine::TryCreateFromLanguage(
        winrt::Windows::Globalization::Language(L"en"));
  }
  if (!engine) {
    throw winrt::hresult_error(E_FAIL,
                               winrt::hstring(L"OcrEngine unavailable"));
  }

  const float bw =
      std::max(1.f, static_cast<float>(bitmap.PixelWidth()));
  const float bh =
      std::max(1.f, static_cast<float>(bitmap.PixelHeight()));

  OcrResult ocr_result = engine.RecognizeAsync(bitmap).get();
  std::wstringstream out;
  EncodableList lines_out;
  for (const auto& line : ocr_result.Lines()) {
    out << std::wstring{line.Text()} << L'\n';

    EncodableMap line_map;
    std::string utf8 = winrt::to_string(winrt::hstring{line.Text()});
    line_map[EncodableValue("text")] = EncodableValue(std::move(utf8));

    float min_x = 1e9f;
    float min_y = 1e9f;
    float max_x = 0.f;
    float max_y = 0.f;
    bool has_rect = false;
    for (const auto& word : line.Words()) {
      auto r = word.BoundingRect();
      min_x = std::min(min_x, r.X);
      min_y = std::min(min_y, r.Y);
      max_x = std::max(max_x, r.X + r.Width);
      max_y = std::max(max_y, r.Y + r.Height);
      has_rect = true;
    }
    if (has_rect && max_x > min_x && max_y > min_y) {
      line_map[EncodableValue("left")] =
          EncodableValue(static_cast<double>(min_x / bw));
      line_map[EncodableValue("top")] =
          EncodableValue(static_cast<double>(min_y / bh));
      line_map[EncodableValue("width")] =
          EncodableValue(static_cast<double>((max_x - min_x) / bw));
      line_map[EncodableValue("height")] =
          EncodableValue(static_cast<double>((max_y - min_y) / bh));
    }
    lines_out.push_back(EncodableValue(std::move(line_map)));
  }
  std::wstring text = out.str();
  if (!text.empty() && text.back() == L'\n') {
    text.pop_back();
  }
  EncodableMap map;
  map[EncodableValue("text")] =
      EncodableValue(winrt::to_string(winrt::hstring{text}));
  map[EncodableValue("lines")] = EncodableValue(std::move(lines_out));
  return map;
}

EncodableMap AiHstringToMap(const winrt::hstring& h) {
  std::string full = winrt::to_string(h);
  EncodableList lines_out;
  std::string cur;
  for (char c : full) {
    if (c == '\n') {
      if (!cur.empty()) {
        EncodableMap line_map;
        line_map[EncodableValue("text")] = EncodableValue(cur);
        lines_out.push_back(EncodableValue(std::move(line_map)));
        cur.clear();
      }
    } else {
      cur.push_back(c);
    }
  }
  if (!cur.empty()) {
    EncodableMap line_map;
    line_map[EncodableValue("text")] = EncodableValue(cur);
    lines_out.push_back(EncodableValue(std::move(line_map)));
  }
  EncodableMap map;
  map[EncodableValue("text")] = EncodableValue(std::move(full));
  map[EncodableValue("lines")] = EncodableValue(std::move(lines_out));
  return map;
}

EncodableMap RecognizeFromWidePathMap(const std::wstring& wide_path) {
  auto bitmap = LoadSoftwareBitmapFromWidePath(wide_path);

#if defined(SPLITBAE_WASDK_AI_OCR)
  try {
    if (auto ai_text = TryRecognizeWithAiImaging(bitmap)) {
      return AiHstringToMap(*ai_text);
    }
  } catch (const winrt::hresult_error&) {
    // Fall through to Media OCR (runtime not bootstrapped, no NPU, etc.).
  }
#endif

  return RecognizeWithMediaOcrMap(bitmap);
}

void FillProbeMap(EncodableMap& map) {
  map[EncodableValue("ready")] = EncodableValue(true);
  map[EncodableValue("onDevice")] = EncodableValue(true);

#if defined(SPLITBAE_WASDK_AI_OCR)
  try {
    using winrt::Microsoft::Windows::AI::AIFeatureReadyState;
    using winrt::Microsoft::Windows::AI::Imaging::TextRecognizer;

    AIFeatureReadyState state = TextRecognizer::GetReadyState();
    switch (state) {
      case AIFeatureReadyState::Ready:
        map[EncodableValue("engine")] =
            EncodableValue("windows.ai.imaging");
        map[EncodableValue("detail")] =
            EncodableValue("ai_imaging_ready");
        return;
      case AIFeatureReadyState::NotSupportedOnCurrentSystem:
        map[EncodableValue("engine")] =
            EncodableValue("windows.media.ocr");
        map[EncodableValue("detail")] = EncodableValue(
            "ai_imaging_not_supported_on_system");
        return;
      case AIFeatureReadyState::NotReady:
        map[EncodableValue("engine")] =
            EncodableValue("windows.media.ocr");
        map[EncodableValue("detail")] =
            EncodableValue("ai_imaging_model_not_ready");
        return;
      case AIFeatureReadyState::DisabledByUser:
        map[EncodableValue("engine")] =
            EncodableValue("windows.media.ocr");
        map[EncodableValue("detail")] =
            EncodableValue("ai_imaging_disabled_by_user");
        return;
      default:
        break;
    }
  } catch (const winrt::hresult_error&) {
    map[EncodableValue("engine")] = EncodableValue("windows.media.ocr");
    map[EncodableValue("detail")] =
        EncodableValue("ai_imaging_probe_failed");
    return;
  }
#endif

  map[EncodableValue("engine")] = EncodableValue("windows.media.ocr");
  map[EncodableValue("detail")] = EncodableValue("ok");
}

std::unique_ptr<flutter::MethodChannel<EncodableValue>> g_receipt_ocr_channel;

}  // namespace

void RegisterReceiptOcrChannel(flutter::FlutterEngine* engine) {
  if (!engine) {
    return;
  }

  try {
    winrt::init_apartment(winrt::apartment_type::single_threaded);
  } catch (const winrt::hresult_error&) {
  }

  g_receipt_ocr_channel =
      std::make_unique<flutter::MethodChannel<EncodableValue>>(
          engine->messenger(), "splitbae/receipt_ocr",
          &flutter::StandardMethodCodec::GetInstance());

  g_receipt_ocr_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        if (call.method() == "probe") {
          EncodableMap map;
          FillProbeMap(map);
          result->Success(EncodableValue(std::move(map)));
          return;
        }

        if (call.method() != "recognizeText") {
          result->NotImplemented();
          return;
        }

        const auto* path = std::get_if<std::string>(call.arguments());
        if (!path || path->empty()) {
          result->Error("bad_args", "Missing path", nullptr);
          return;
        }

        try {
          std::wstring wide = Utf8PathToWide(*path);
          if (wide.empty()) {
            result->Error("bad_args", "Invalid UTF-8 path", nullptr);
            return;
          }
          EncodableMap payload = RecognizeFromWidePathMap(wide);
          result->Success(EncodableValue(std::move(payload)));
        } catch (const winrt::hresult_error& e) {
          std::string msg = winrt::to_string(e.message());
          result->Error("ocr", msg, nullptr);
        } catch (const std::exception& e) {
          result->Error("ocr", e.what(), nullptr);
        } catch (...) {
          result->Error("ocr", "Unknown OCR failure", nullptr);
        }
      });
}
