#!/bin/bash
set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RUST_DIR="$PROJECT_DIR/rust"
OUTPUT_DIR="$SCRIPT_DIR"

echo "🦀 Building Rust library for macOS..."
echo "Project dir: $PROJECT_DIR"
echo "Rust dir: $RUST_DIR"
echo "Output dir: $OUTPUT_DIR"

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "❌ Error: Rust is not installed. Please install Rust from https://rustup.rs/"
    exit 1
fi

# Build the Rust library
cd "$RUST_DIR"
echo "Building release version..."
cargo build --release

# Copy the built library to the macOS directory
LIB_NAME="libflutter_tikz_rust_native.dylib"
cp "target/release/$LIB_NAME" "$OUTPUT_DIR/$LIB_NAME"

echo "✅ Rust library built successfully: $OUTPUT_DIR/$LIB_NAME"

