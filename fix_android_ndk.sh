#!/usr/bin/env bash
set -euo pipefail

export ANDROID_HOME="/usr/lib/android-sdk"
SDKMGR="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

echo "=== Installing Android NDK 28.2.13676358 ==="
echo "(Gradle requests this for native code; SDK dir needs sudo to write)"
echo ""

yes | sudo -E env "ANDROID_HOME=$ANDROID_HOME" "$SDKMGR" \
    --install \
    "ndk;28.2.13676358" 2>&1 | tail -8

echo ""
echo "=== Verifying ==="
ls -d "$ANDROID_HOME/ndk/28.2.13676358" 2>/dev/null && echo "✓ NDK installed" || echo "✗ NDK MISSING"

echo ""
echo "=== Done! ==="
