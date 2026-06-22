#!/usr/bin/env bash
set -euo pipefail

export ANDROID_HOME="/usr/lib/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

echo "[1/2] Accepting all licenses..."
yes | sudo "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses 2>&1 | grep -E "(Accept|accepted|All SDK)" || true

echo "[2/2] Installing platforms;android-35 and build-tools;35.0.0..."
yes | sudo "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --install "platforms;android-35" "build-tools;35.0.0" 2>&1 | tail -5

echo ""
echo "=== Done! ==="
echo "Run 'flutter doctor' to verify."
