#!/usr/bin/env bash
set -euo pipefail

export ANDROID_HOME="/usr/lib/android-sdk"
SDKMGR="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

echo "=== Installing Android SDK 36 + Build-Tools 28.0.3 ==="
echo "(requires sudo to write into $ANDROID_HOME)"
echo ""

yes | sudo -E env "ANDROID_HOME=$ANDROID_HOME" "$SDKMGR" \
    --install \
    "platforms;android-36" \
    "build-tools;28.0.3" 2>&1 | tail -10

echo ""
echo "=== Verifying install ==="
ls -d "$ANDROID_HOME/platforms/android-36" 2>/dev/null && echo "✓ android-36 installed" || echo "✗ android-36 MISSING"
ls -d "$ANDROID_HOME/build-tools/28.0.3" 2>/dev/null && echo "✓ build-tools 28.0.3 installed" || echo "✗ build-tools 28.0.3 MISSING"

echo ""
echo "=== Done! ==="
