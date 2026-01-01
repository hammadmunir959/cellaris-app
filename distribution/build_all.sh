#!/bin/bash
set -e

# Ensure we are in the distribution directory
cd "$(dirname "$0")"

echo "========================================"
echo "    MBM PACKAGING & BUILD SYSTEM"
echo "========================================"

# Check for Android support
if [ ! -d "../android" ]; then
    echo "[!] Android platform not detected. Adding Android support..."
    cd ..
    flutter create --platforms=android .
    cd distribution
fi

# Determine project root
PROJECT_ROOT=".."

echo "[1/3] Building for Windows..."
cd "$PROJECT_ROOT"
flutter build windows --release
echo "      > Windows build complete."

echo "[2/3] Building for Linux..."
flutter build linux --release
echo "      > Linux build complete."

echo "[3/3] Building for Android..."
flutter build apk --release
echo "      > Android build complete."

echo "========================================"
echo "SUCCESS! All raw binaries built."
echo "Windows: build/windows/runner/Release"
echo "Linux:   build/linux/x64/release/bundle"
echo "Android: build/app/outputs/flutter-apk/app-release.apk"
echo "========================================"
