#!/bin/bash

# DMG Creation Script for GhostSay CLI Tool
# Creates a professional DMG with installer script

set -e

BINARY_PATH="$1"
OUTPUT_DMG="$2"
PRODUCT_NAME="GhostSay"
VOLUME_NAME="${PRODUCT_NAME} Installer"

if [ -z "$BINARY_PATH" ] || [ -z "$OUTPUT_DMG" ]; then
    echo "Usage: $0 <binary_path> <output_dmg>"
    exit 1
fi

# Create temporary directory for DMG contents
DMG_TEMP=$(mktemp -d)
echo "📁 Creating DMG contents in: ${DMG_TEMP}"

# Create app bundle
echo "📦 Creating app bundle..."
./scripts/create-app-bundle.sh "$BINARY_PATH"
mv GhostSay.app "${DMG_TEMP}/"

# Create Applications symlink
echo "🔗 Creating Applications symlink..."
ln -s /Applications "${DMG_TEMP}/Applications"

# Create README for drag-and-drop
cat > "${DMG_TEMP}/README.txt" << EOF
GhostSay GUI Application

Installation:
1. Drag GhostSay.app to the Applications folder
2. Launch GhostSay from Applications, Launchpad, or Spotlight
3. The app will appear in your menu bar and Dock

Features:
- Menu bar application for easy access
- Settings window for configuration
- Server management capabilities
- Modern SwiftUI interface

Uninstallation:
- Delete GhostSay.app from Applications

For more information, visit: https://github.com/yourusername/ghostsay
EOF

# Create final compressed DMG directly
echo "💽 Creating compressed DMG..."
hdiutil create \
    -volname "${VOLUME_NAME}" \
    -srcfolder "${DMG_TEMP}" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    -imagekey zlib-level=6 \
    "${OUTPUT_DMG}"

# Cleanup
rm -rf "${DMG_TEMP}"

echo "✅ DMG created: ${OUTPUT_DMG}"