#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

#if defined(SPLITBAE_WASDK_BOOTSTRAP)
#include <WindowsAppSDK-VersionInfo.h>
#include <MddBootstrap.h>
#endif

// On-device receipt OCR (`splitbae/receipt_ocr`) is registered from
// `FlutterWindow::OnCreate` in `flutter_window.cpp` via `receipt_ocr_win.cpp`
// (WinRT `Windows.Media.Ocr`). NPU-oriented `Microsoft.Windows.AI.Imaging`
// text recognition can be layered in when the Windows App SDK is linked; see
// `receipt_ocr_win.cpp` header comment.

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

#if defined(SPLITBAE_WASDK_BOOTSTRAP)
  // Unpackaged .exe: load the Windows App SDK framework package before any
  // WinRT APIs from that SDK (e.g. AI Imaging OCR). Packaged / other builds
  // omit this via CMake when bootstrap headers are not present.
  const bool wasdk_bootstrap_initialized = SUCCEEDED(MddBootstrapInitialize(
      WINDOWSAPPSDK_RELEASE_MAJORMINOR, WINDOWSAPPSDK_RELEASE_VERSION_TAG_W,
      {WINDOWSAPPSDK_RUNTIME_VERSION_UINT64}));
#endif

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"splitbae", origin, size)) {
#if defined(SPLITBAE_WASDK_BOOTSTRAP)
    if (wasdk_bootstrap_initialized) {
      MddBootstrapUninitialize();
    }
#endif
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

#if defined(SPLITBAE_WASDK_BOOTSTRAP)
  if (wasdk_bootstrap_initialized) {
    MddBootstrapUninitialize();
  }
#endif
  ::CoUninitialize();
  return EXIT_SUCCESS;
}
