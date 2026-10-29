#!/usr/bin/env bash
set -euo pipefail

echo "==> Running Swipy Core Test Suite..."
swift run SwipyTestRunner

echo "==> Verifying Swipy.app bundle..."
if [ -d "build/Swipy.app" ]; then
    codesign --verify --deep --strict build/Swipy.app
    echo "==> Swipy.app bundle signature verified."
fi

echo "==> All test suites passed successfully!"
