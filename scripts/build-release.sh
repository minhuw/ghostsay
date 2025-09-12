#!/bin/bash

# Local macOS Build Script
# Builds universal binary and creates DMG (with optional signing)

set -e

# Configuration
PRODUCT_NAME="GhostSay"
VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")
SIGN_BUILD="${SIGN_BUILD:-false}"  # Set to "true" to enable signing

# Check for signing configuration
if [ "$SIGN_BUILD" = "true" ]; then
    TEAM_ID="${APPLE_TEAM_ID}"
    DEVELOPER_ID_CERT="${DEVELOPER_ID_CERT:-Developer ID Application}"
    KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-notarization-profile}"
    
    if [ -z "${TEAM_ID}" ]; then
        echo "⚠️  Warning: APPLE_TEAM_ID not set. Run without signing."
        SIGN_BUILD="false"
    fi
fi

# Directories
BUILD_DIR=".build"
TEMP_DIR="temp"

echo "🚀 Building ${PRODUCT_NAME} ${VERSION}..."
if [ "$SIGN_BUILD" = "true" ]; then
    echo "🔐 Code signing enabled"
else
    echo "📦 Building without code signing (for testing)"
fi

# Clean previous builds
rm -rf "${TEMP_DIR}"
mkdir -p "${TEMP_DIR}"

# Build universal binary
echo "📦 Building universal binary..."
swift build --configuration release --arch arm64 --arch x86_64

# Verify binary architecture
echo "🔍 Verifying binary architecture..."
file "${BUILD_DIR}/apple/Products/Release/${PRODUCT_NAME}"
lipo -info "${BUILD_DIR}/apple/Products/Release/${PRODUCT_NAME}"

# Copy binary to temp directory
cp "${BUILD_DIR}/apple/Products/Release/${PRODUCT_NAME}" "${TEMP_DIR}/${PRODUCT_NAME}"

# Optional code signing
if [ "$SIGN_BUILD" = "true" ]; then
    echo "✍️  Code signing binary..."
    xcrun codesign \
        --sign "${DEVELOPER_ID_CERT}" \
        --options runtime \
        --timestamp \
        --verbose \
        "${TEMP_DIR}/${PRODUCT_NAME}"
    
    # Verify code signature
    echo "🔐 Verifying code signature..."
    xcrun codesign --verify --verbose "${TEMP_DIR}/${PRODUCT_NAME}"
    
    # Optional notarization
    if xcrun notarytool list --keychain-profile "${KEYCHAIN_PROFILE}" >/dev/null 2>&1; then
        echo "📦 Creating archive for notarization..."
        cd "${TEMP_DIR}"
        zip -r "${PRODUCT_NAME}-${VERSION}.zip" "${PRODUCT_NAME}"
        cd ..
        
        echo "📋 Submitting for notarization..."
        xcrun notarytool submit \
            "${TEMP_DIR}/${PRODUCT_NAME}-${VERSION}.zip" \
            --keychain-profile "${KEYCHAIN_PROFILE}" \
            --wait
        echo "✅ Notarization complete!"
    else
        echo "⚠️  Skipping notarization (no keychain profile found)"
        echo "💡 To set up notarization:"
        echo "   xcrun notarytool store-credentials --apple-id your@email.com --team-id TEAMID notarization-profile"
    fi
fi

# Create DMG
echo "💽 Creating DMG..."
OUTPUT_DMG="${PRODUCT_NAME}-${VERSION}.dmg"
./scripts/create-dmg.sh "${TEMP_DIR}/${PRODUCT_NAME}" "${OUTPUT_DMG}"

# Optional DMG signing
if [ "$SIGN_BUILD" = "true" ]; then
    echo "✍️  Signing DMG..."
    xcrun codesign \
        --sign "${DEVELOPER_ID_CERT}" \
        --timestamp \
        "${OUTPUT_DMG}"
    
    # Optional DMG notarization
    if xcrun notarytool list --keychain-profile "${KEYCHAIN_PROFILE}" >/dev/null 2>&1; then
        echo "📋 Notarizing DMG..."
        xcrun notarytool submit \
            "${OUTPUT_DMG}" \
            --keychain-profile "${KEYCHAIN_PROFILE}" \
            --wait
        
        echo "📎 Stapling notarization ticket..."
        xcrun stapler staple "${OUTPUT_DMG}"
    else
        echo "⚠️  Skipping DMG notarization (no keychain profile found)"
    fi
fi

# Cleanup
echo "🧹 Cleaning up temporary files..."
rm -rf "${TEMP_DIR}"

echo "🎉 Build complete!"
echo "📁 DMG: ${OUTPUT_DMG}"
echo ""
if [ "$SIGN_BUILD" = "true" ]; then
    echo "✅ Signed and notarized build ready for distribution"
else
    echo "📋 For distribution, run with signing:"
    echo "   SIGN_BUILD=true ./scripts/build-release.sh"
    echo ""
    echo "📋 To set up signing:"
    echo "   export APPLE_TEAM_ID='YOUR_TEAM_ID'"
    echo "   export DEVELOPER_ID_CERT='Developer ID Application: Your Name (TEAMID)'"
    echo "   xcrun notarytool store-credentials --apple-id you@example.com --team-id TEAMID notarization-profile"
fi