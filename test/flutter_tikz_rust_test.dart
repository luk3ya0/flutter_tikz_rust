import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tikz_rust/flutter_tikz_rust.dart';
import 'package:flutter_tikz_rust/flutter_tikz_rust_platform_interface.dart';
import 'package:flutter_tikz_rust/flutter_tikz_rust_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterTikzRustPlatform
    with MockPlatformInterfaceMixin
    implements FlutterTikzRustPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterTikzRustPlatform initialPlatform = FlutterTikzRustPlatform.instance;

  test('$MethodChannelFlutterTikzRust is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterTikzRust>());
  });

  test('getPlatformVersion', () async {
    FlutterTikzRust flutterTikzRustPlugin = FlutterTikzRust();
    MockFlutterTikzRustPlatform fakePlatform = MockFlutterTikzRustPlatform();
    FlutterTikzRustPlatform.instance = fakePlatform;

    expect(await flutterTikzRustPlugin.getPlatformVersion(), '42');
  });
}
