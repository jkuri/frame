#!/bin/bash
set -e

APP_NAME="Reframed"
BUILD_DIR=".build/Build/Products/Release"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${BUILD_DIR}/${APP_NAME}.app/Contents/Info.plist" 2>/dev/null || echo "0.0.0")
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_TEMP="/tmp/${APP_NAME}_dmg_temp"
DMG_TEMP_IMG="/tmp/temp_${DMG_NAME}"
DMG_FINAL="dist/${DMG_NAME}"
ENTITLEMENTS="Reframed/Reframed.entitlements"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

if [ ! -d "${APP_BUNDLE}" ]; then
    error "App bundle not found at ${APP_BUNDLE}. Run 'make release' first."
fi

BINARY_PATH="${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
if [ -f "${BINARY_PATH}" ]; then
    ARCHS=$(lipo -archs "${BINARY_PATH}" 2>/dev/null || echo "unknown")
    if [[ "$ARCHS" == *"x86_64"* ]] && [[ "$ARCHS" == *"arm64"* ]]; then
        info "Universal binary confirmed (${ARCHS})"
    else
        warn "Binary is NOT universal. Architectures found: ${ARCHS}"
        warn "Build with: swift build -c release --arch arm64 --arch x86_64"
        warn "The DMG will only work on ${ARCHS} machines."
    fi
fi

SIGNING_IDENTITY=""
NOTARIZE=false
APPLE_ID=""
TEAM_ID=""
APP_PASSWORD=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign)
            SIGNING_IDENTITY="$2"
            shift 2
            ;;
        --notarize)
            NOTARIZE=true
            shift
            ;;
        --apple-id)
            APPLE_ID="$2"
            shift 2
            ;;
        --team-id)
            TEAM_ID="$2"
            shift 2
            ;;
        --password)
            APP_PASSWORD="$2"
            shift 2
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

if [ -z "${SIGNING_IDENTITY}" ]; then
    : "${SIGNING_IDENTITY:=${REFRAMED_SIGNING_IDENTITY:-}}"
fi
if [ -z "${APPLE_ID}" ]; then
    : "${APPLE_ID:=${REFRAMED_APPLE_ID:-}}"
fi
if [ -z "${TEAM_ID}" ]; then
    : "${TEAM_ID:=${REFRAMED_TEAM_ID:-}}"
fi
if [ -z "${APP_PASSWORD}" ]; then
    : "${APP_PASSWORD:=${REFRAMED_APP_PASSWORD:-}}"
fi

if [ -n "${SIGNING_IDENTITY}" ]; then
    info "Signing app bundle with: ${SIGNING_IDENTITY}"

    find "${APP_BUNDLE}/Contents/Frameworks" -type f \( -name "*.dylib" -o -name "*.framework" \) 2>/dev/null | while read -r lib; do
        codesign --force --options runtime --sign "${SIGNING_IDENTITY}" "${lib}"
    done

    codesign --deep --force --options runtime \
        --entitlements "${ENTITLEMENTS}" \
        --sign "${SIGNING_IDENTITY}" \
        "${APP_BUNDLE}"

    info "Verifying code signature..."
    codesign --verify --deep --strict "${APP_BUNDLE}"
    info "Code signature verified"
else
    warn "No signing identity provided. DMG will not pass Gatekeeper."
    warn "Use --sign 'Developer ID Application: ...' or set REFRAMED_SIGNING_IDENTITY"
fi

info "Creating DMG for ${APP_NAME} v${VERSION}..."

rm -rf "${DMG_TEMP}"
rm -f "${DMG_TEMP_IMG}"

info "Setting up DMG contents..."
mkdir -p "dist"
mkdir -p "${DMG_TEMP}"
cp -R "${APP_BUNDLE}" "${DMG_TEMP}/"
ln -s /Applications "${DMG_TEMP}/Applications"

if [ -f "scripts/dmg-background.png" ]; then
    mkdir -p "${DMG_TEMP}/.background"
    cp "scripts/dmg-background.png" "${DMG_TEMP}/.background/background.png"
fi

APP_SIZE=$(du -sm "${APP_BUNDLE}" | cut -f1)
DMG_SIZE=$((APP_SIZE + 20))

info "Creating temporary DMG (${DMG_SIZE}MB)..."

hdiutil create -srcfolder "${DMG_TEMP}" \
    -volname "${APP_NAME}" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${DMG_SIZE}m \
    "${DMG_TEMP_IMG}" \
    -quiet

info "Mounting DMG for customization..."

MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TEMP_IMG}" | grep "/Volumes/${APP_NAME}" | tail -1 | cut -f3-)

if [ -z "${MOUNT_DIR}" ]; then
    error "Failed to mount DMG"
fi

info "Customizing DMG window..."

osascript <<EOF
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 100, 900, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "${APP_NAME}.app" of container window to {120, 150}
        set position of item "Applications" of container window to {380, 150}
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
EOF

sync
sleep 5

info "Finalizing DMG..."

hdiutil detach "${MOUNT_DIR}" -quiet

rm -f "${DMG_FINAL}"
hdiutil convert "${DMG_TEMP_IMG}" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${DMG_FINAL}" \
    -quiet

rm -rf "${DMG_TEMP}"
rm -f "${DMG_TEMP_IMG}"

if [ -n "${SIGNING_IDENTITY}" ]; then
    info "Signing DMG..."
    codesign --force --sign "${SIGNING_IDENTITY}" "${DMG_FINAL}"
fi

if [ "${NOTARIZE}" = true ]; then
    if [ -z "${APPLE_ID}" ] || [ -z "${TEAM_ID}" ] || [ -z "${APP_PASSWORD}" ]; then
        error "Notarization requires --apple-id, --team-id, and --password (or REFRAMED_APPLE_ID, REFRAMED_TEAM_ID, REFRAMED_APP_PASSWORD env vars)"
    fi

    info "Submitting DMG for notarization..."
    xcrun notarytool submit "${DMG_FINAL}" \
        --apple-id "${APPLE_ID}" \
        --team-id "${TEAM_ID}" \
        --password "${APP_PASSWORD}" \
        --wait

    info "Stapling notarization ticket..."
    xcrun stapler staple "${DMG_FINAL}"

    info "Verifying notarization..."
    spctl --assess --type open --context context:primary-signature -v "${DMG_FINAL}"
    info "Notarization verified"
fi

FINAL_SIZE=$(du -h "${DMG_FINAL}" | cut -f1 | xargs)

info "Successfully created ${DMG_FINAL} (${FINAL_SIZE})"
