import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_tikz_rust_platform_interface.dart';

/// An implementation of [FlutterTikzRustPlatform] that uses method channels.
class MethodChannelFlutterTikzRust extends FlutterTikzRustPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_tikz_rust');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
