Pod::Spec.new do |s|
  s.name             = 'flutter_tikz_rust'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for rendering TikZ diagrams using Rust.'
  s.description      = <<-DESC
A Flutter plugin for rendering TikZ diagrams using Rust and rust_tikz.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  # Build Rust library before compilation
  s.script_phase = {
    :name => 'Build Rust Library',
    :script => 'bash "${PODS_TARGET_SRCROOT}/build_rust.sh"',
    :execution_position => :before_compile
  }

  # Include the Rust dynamic library
  s.vendored_libraries = 'libflutter_tikz_rust_native.dylib'
end
