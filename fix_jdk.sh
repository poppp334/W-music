#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing OpenJDK 21 JDK (provides javac) ==="
sudo apt-get update -y
sudo apt-get install -y openjdk-21-jdk

echo ""
echo "=== Setting JDK 21 as default ==="
sudo update-java-alternatives --set java-1.21.0-openjdk-amd64 2>/dev/null || \
    sudo update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java

echo ""
echo "=== Verifying ==="
javac -version 2>&1 && echo "✓ javac available" || echo "✗ javac STILL MISSING"

echo ""
echo "=== Done! ==="
