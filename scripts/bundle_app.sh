#!/usr/bin/env bash
set -euo pipefail

echo "==> Building Swipy in Release mode..."
swift build -c release

APP_NAME="Swipy"
BUILD_DIR="build/${APP_NAME}.app"
CONTENTS_DIR="${BUILD_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Packaging ${APP_NAME}.app bundle..."
rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Swipy</string>
    <key>CFBundleIdentifier</key>
    <string>com.swipy.Swipy</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Swipy</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSCameraUsageDescription</key>
    <string>Swipy requires camera access to detect hand gestures for touchless cursor control. Video frames are processed entirely on-device in real time and are never recorded or transmitted.</string>
</dict>
</plist>
EOF

echo "==> Signing ${APP_NAME}.app with camera entitlements..."
codesign --force --deep --sign - --entitlements Swipy.entitlements "${BUILD_DIR}"

echo "==> Verifying signature..."
codesign --verify --deep --strict --verbose=2 "${BUILD_DIR}"

echo "==> Successfully packaged and verified ${BUILD_DIR}!"
