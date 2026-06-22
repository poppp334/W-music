#!/usr/bin/env bash
set -euo pipefail

export ANDROID_HOME="/usr/lib/android-sdk"
SDKMGR="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

echo "=== Installing Android Build-Tools 36.0.0 ==="
yes | sudo -E env "ANDROID_HOME=$ANDROID_HOME" "$SDKMGR" \
    --install "build-tools;36.0.0" 2>&1 | tail -8

echo ""
echo "=== Verifying ==="
ls -d "$ANDROID_HOME/build-tools/36.0.0" 2>/dev/null && echo "✓ build-tools 36.0.0 installed" || echo "✗ MISSING"

echo ""
echo "=== Done! ==="
