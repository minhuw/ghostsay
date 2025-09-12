#!/bin/bash

# Create macOS App Bundle for CLI Tool
# This wraps the CLI binary in a proper .app structure

set -e

BINARY_PATH="$1"
APP_NAME="GhostSay"
BUNDLE_ID="com.yourcompany.ghostsay"
VERSION=$(git describe --tags --always 2>/dev/null || echo "1.0.0")

if [ -z "$BINARY_PATH" ]; then
    echo "Usage: $0 <binary_path>"
    exit 1
fi

# Create app bundle structure
APP_BUNDLE="${APP_NAME}.app"
rm -rf "${APP_BUNDLE}"

echo "📦 Creating app bundle: ${APP_BUNDLE}"

# Create directory structure
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy the GUI app binary
cp "${BINARY_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy app icon
if [ -f "Resources/ghostsay.icns" ]; then
    echo "📎 Adding app icon..."
    cp "Resources/ghostsay.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
else
    echo "⚠️  Icon file Resources/ghostsay.icns not found, skipping icon"
fi

# Create Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF


echo "✅ App bundle created: ${APP_BUNDLE}"
echo "📋 Bundle contains:"
echo "   - GUI app binary: Contents/MacOS/${APP_NAME}"
echo "   - App icon: Contents/Resources/AppIcon.icns"
echo "   - Info.plist with bundle metadata"