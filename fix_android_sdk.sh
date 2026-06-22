#!/usr/bin/env bash
set -euo pipefail

SDK_DIR="/usr/lib/android-sdk"
CMDTOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
ZIP="/tmp/cmdline-tools.zip"
CMDTOOLS_VER="latest"

echo "=== Stitch: Android SDK Setup ==="
echo ""

# --- 1. Install cmdline-tools ---
echo "[1/4] Downloading cmdline-tools..."
curl -L -o "$ZIP" "$CMDTOOLS_URL"

echo "[2/4] Installing cmdline-tools into $SDK_DIR..."
sudo mkdir -p "$SDK_DIR/cmdline-tools"
sudo unzip -o "$ZIP" -d "$SDK_DIR/cmdline-tools/"
# sdkmanager expects the path: .../cmdline-tools/latest/bin/sdkmanager
# The zip extracts as "cmdline-tools/", so rename:
if [ -d "$SDK_DIR/cmdline-tools/cmdline-tools" ] && [ ! -d "$SDK_DIR/cmdline-tools/$CMDTOOLS_VER" ]; then
    sudo mv "$SDK_DIR/cmdline-tools/cmdline-tools" "$SDK_DIR/cmdline-tools/$CMDTOOLS_VER"
fi

export ANDROID_HOME="$SDK_DIR"
export PATH="$SDK_DIR/cmdline-tools/$CMDTOOLS_VER/bin:$PATH"

echo "[3/4] Accepting all Android SDK licenses..."
yes | sdkmanager --licenses 2>&1 | tail -5

echo "[4/4] Installing required platform SDK & build-tools..."
# Flutter 3.44 needs compileSdk 35 / build-tools 35.x
sdkmanager --install "platforms;android-35" "build-tools;35.0.0" 2>&1 | tail -5

# Cleanup
rm -f "$ZIP"

echo ""
echo "=== Done! ==="
echo "Run 'flutter doctor' to verify."
