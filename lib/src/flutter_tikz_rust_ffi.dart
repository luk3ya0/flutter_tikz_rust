import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

/// Typedef for the tikz_to_svg function
typedef TikzToSvgNative = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>);
typedef TikzToSvgDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>);

/// Typedef for the free_string function
typedef FreeStringNative = ffi.Void Function(ffi.Pointer<Utf8>);
typedef FreeStringDart = void Function(ffi.Pointer<Utf8>);

class FlutterTikzRust {
  static ffi.DynamicLibrary? _dylib;
  static TikzToSvgDart? _tikzToSvg;
  static FreeStringDart? _freeString;

  /// Initialize the native library
  static void init() {
    if (_dylib != null) return;

    // Load the dynamic library
    if (Platform.isMacOS) {
      // Try to load from the plugin's macOS directory
      try {
        _dylib = ffi.DynamicLibrary.open(
          'flutter_tikz_rust.framework/Versions/A/flutter_tikz_rust',
        );
      } catch (e) {
        // Fallback to direct library name
        _dylib = ffi.DynamicLibrary.open(
          'libflutter_tikz_rust_native.dylib',
        );
      }
    } else if (Platform.isIOS) {
      _dylib = ffi.DynamicLibrary.process();
    } else if (Platform.isAndroid) {
      _dylib = ffi.DynamicLibrary.open('libflutter_tikz_rust_native.so');
    } else if (Platform.isLinux) {
      _dylib = ffi.DynamicLibrary.open('libflutter_tikz_rust_native.so');
    } else {
      throw UnsupportedError('Platform not supported');
    }

    // Lookup functions
    _tikzToSvg = _dylib!
        .lookup<ffi.NativeFunction<TikzToSvgNative>>('tikz_to_svg')
        .asFunction();
    _freeString = _dylib!
        .lookup<ffi.NativeFunction<FreeStringNative>>('free_string')
        .asFunction();
  }

  /// Convert TikZ code to SVG
  /// 
  /// Returns the SVG string on success, or throws an exception on error.
  static String tikzToSvg(String tikzCode) {
    init();

    // Convert Dart string to C string
    final tikzCodePtr = tikzCode.toNativeUtf8();

    try {
      // Call native function
      final resultPtr = _tikzToSvg!(tikzCodePtr);

      if (resultPtr.address == 0) {
        throw Exception('Failed to convert TikZ to SVG: null pointer returned');
      }

      // Convert C string to Dart string
      final result = resultPtr.toDartString();

      // Free the C string
      _freeString!(resultPtr);

      // Check if result is an error message
      if (result.startsWith('ERROR: ')) {
        throw Exception(result.substring(7));
      }

      return result;
    } finally {
      // Free the input string
      malloc.free(tikzCodePtr);
    }
  }
}
