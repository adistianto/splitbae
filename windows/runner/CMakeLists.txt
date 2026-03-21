cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "receipt_ocr_win.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_link_libraries(${BINARY_NAME} PRIVATE "WindowsApp.lib")

# Optional: `Microsoft.Windows.AI.Imaging.TextRecognizer` (Copilot+ / NPU path
# per Microsoft when `TextRecognizer::GetReadyState()` is Ready). Enables
# SPLITBAE_WASDK_AI_OCR when headers are found — NuGet
# %USERPROFILE%\.nuget\packages\microsoft.windowsappsdk\<ver>\build\native\include
# or set env SPLITBAE_WINDOWS_APP_SDK_INCLUDE to that include directory.
set(_splitbae_wasdk_include "")
if(WIN32)
  if(DEFINED ENV{SPLITBAE_WINDOWS_APP_SDK_INCLUDE})
    if(EXISTS "$ENV{SPLITBAE_WINDOWS_APP_SDK_INCLUDE}/winrt/Microsoft.Windows.AI.Imaging.h")
      set(_splitbae_wasdk_include "$ENV{SPLITBAE_WINDOWS_APP_SDK_INCLUDE}")
    endif()
  endif()
  if(NOT _splitbae_wasdk_include AND DEFINED ENV{USERPROFILE})
    file(GLOB _wasdk_pkg_versions "$ENV{USERPROFILE}/.nuget/packages/microsoft.windowsappsdk/*")
    if(_wasdk_pkg_versions)
      list(SORT _wasdk_pkg_versions ORDER DESCENDING)
      foreach(_ver ${_wasdk_pkg_versions})
        foreach(_inc "build/native/include" "include")
          set(_cand "${_ver}/${_inc}")
          if(EXISTS "${_cand}/winrt/Microsoft.Windows.AI.Imaging.h")
            set(_splitbae_wasdk_include "${_cand}")
            break()
          endif()
        endforeach()
        if(_splitbae_wasdk_include)
          break()
        endif()
      endforeach()
    endif()
  endif()
endif()
if(_splitbae_wasdk_include)
  message(STATUS "SplitBae: Windows App SDK AI OCR headers found; SPLITBAE_WASDK_AI_OCR enabled")
  message(STATUS "  Include: ${_splitbae_wasdk_include}")
  target_include_directories(${BINARY_NAME} PRIVATE "${_splitbae_wasdk_include}")
  target_compile_definitions(${BINARY_NAME} PRIVATE SPLITBAE_WASDK_AI_OCR=1)
endif()

# cppwinrt async `.get()` requires C++ exceptions; the default runner disables
# them globally (`_HAS_EXCEPTIONS=0`).
set_source_files_properties(
  "${CMAKE_CURRENT_SOURCE_DIR}/receipt_ocr_win.cpp"
  PROPERTIES COMPILE_OPTIONS "/EHsc"
)
set_source_files_properties(
  "${CMAKE_CURRENT_SOURCE_DIR}/receipt_ocr_win.cpp"
  PROPERTIES COMPILE_DEFINITIONS "_HAS_EXCEPTIONS=1"
)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
