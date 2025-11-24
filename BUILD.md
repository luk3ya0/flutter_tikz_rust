# Building flutter_tikz_rust

This plugin uses Rust FFI to render TikZ diagrams. The Rust library needs to be compiled before the plugin can be used.

## Prerequisites

1. **Rust**: Install from https://rustup.rs/
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **Flutter**: Make sure Flutter is installed and configured

## Automatic Build

The Rust library should be built automatically when you run:

```bash
flutter pub get
flutter build macos
```

The build script (`macos/build_rust.sh`) will be executed by CocoaPods during the build process.

## Manual Build

If the automatic build fails, you can build manually:

### macOS

```bash
cd rust
cargo build --release
cp target/release/libflutter_tikz_rust_native.dylib ../macos/
```

### Linux

```bash
cd rust
cargo build --release
cp target/release/libflutter_tikz_rust_native.so ../linux/
```

### iOS

```bash
cd rust
# Build for iOS simulator (x86_64)
cargo build --release --target x86_64-apple-ios
# Build for iOS device (aarch64)
cargo build --release --target aarch64-apple-ios
# Create universal library
lipo -create \
  target/x86_64-apple-ios/release/libflutter_tikz_rust_native.a \
  target/aarch64-apple-ios/release/libflutter_tikz_rust_native.a \
  -output ../ios/libflutter_tikz_rust_native.a
```

### Android

```bash
cd rust
# Install Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android

# Build for each architecture
cargo build --release --target aarch64-linux-android
cargo build --release --target armv7-linux-androideabi
cargo build --release --target i686-linux-android
cargo build --release --target x86_64-linux-android

# Copy to Android jniLibs
mkdir -p ../android/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86,x86_64}
cp target/aarch64-linux-android/release/libflutter_tikz_rust_native.so ../android/src/main/jniLibs/arm64-v8a/
cp target/armv7-linux-androideabi/release/libflutter_tikz_rust_native.so ../android/src/main/jniLibs/armeabi-v7a/
cp target/i686-linux-android/release/libflutter_tikz_rust_native.so ../android/src/main/jniLibs/x86/
cp target/x86_64-linux-android/release/libflutter_tikz_rust_native.so ../android/src/main/jniLibs/x86_64/
```

## Troubleshooting

### "Failed to lookup symbol 'tikz_to_svg'"

This means the Rust library wasn't built or wasn't found. Try:

1. Check if Rust is installed: `cargo --version`
2. Manually build the library (see above)
3. Clean and rebuild:
   ```bash
   cd rust
   cargo clean
   cargo build --release
   ```
4. In your Flutter project:
   ```bash
   flutter clean
   flutter pub get
   flutter build macos
   ```

### Build script not running

If the CocoaPods script phase doesn't run:

1. Delete `Pods` directory in your Flutter app
2. Run `pod install` or `flutter build macos`
3. Check the build logs for errors

### Rust not found during build

Make sure Rust is in your PATH. Add to your `~/.zshrc` or `~/.bash_profile`:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

Then restart your terminal or run `source ~/.zshrc`.

