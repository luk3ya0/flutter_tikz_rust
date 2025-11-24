# flutter_tikz_rust

A Flutter plugin for rendering TikZ diagrams using Rust FFI.

## Features

- Render TikZ diagrams to SVG using the `rust_tikz` library
- Support for `tikzpicture`, `tikzcd`, and other TikZ environments
- Automatic dark/light mode adaptation
- Asynchronous rendering with loading indicators

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_tikz_rust:
    git:
      url: https://github.com/luk3ya0/flutter_tikz_rust.git
      ref: main
```

## Building

This plugin requires Rust to be installed. See [BUILD.md](BUILD.md) for detailed build instructions.

**Quick start:**

1. Install Rust: https://rustup.rs/
2. Run `flutter pub get` (the Rust library will be built automatically)

## Usage

```dart
import 'package:flutter_tikz_rust/flutter_tikz_rust.dart';

TikzWidget(
  tikzCode: r'''
\begin{tikzpicture}
\draw[->] (0,0) -- (1,1);
\node at (0.5, 0.5) {Hello};
\end{tikzpicture}
''',
  color: Colors.black,
)
```

## Troubleshooting

If you see "Failed to lookup symbol 'tikz_to_svg'", the Rust library wasn't built. See [BUILD.md](BUILD.md) for manual build instructions.

