#!/usr/bin/env bash
# Archives BoringPhone, exports with an App Store Connect distribution profile,
# and uploads straight to TestFlight using the App Store Connect API key.
#
# Requires:
#   - a paid Apple Developer Program membership (for Family Controls signing)
#   - the App Store Connect app record already created (My Apps > + > New App)
#   - the Family Controls (Distribution) entitlement request approved by Apple
#     (https://developer.apple.com/contact/request/family-controls-distribution)
#     — without it, the upload is rejected at binary validation.
#
# Usage: ci/release_to_testflight.sh

set -euo pipefail
cd "$(dirname "$0")/.."

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ASC_ENV=~/.claude-secrets/appstoreconnect/.env
[ -f "$ASC_ENV" ] || { echo "Missing $ASC_ENV"; exit 1; }
set -a; source "$ASC_ENV"; set +a

BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/BoringPhone.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Archiving (build number stamped via build setting, not a file edit)"
NEW_BUILD=$(date +%Y%m%d%H%M)
xcodebuild archive \
  -project BoringPhone.xcodeproj \
  -scheme BoringPhone \
  -archivePath "$ARCHIVE_PATH" \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  CURRENT_PROJECT_VERSION="$NEW_BUILD"

echo "==> Exporting + uploading to App Store Connect"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist ci/ExportOptions.plist \
  -exportPath "$EXPORT_PATH" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_PRIVATE_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"

echo "==> Uploaded. Processing on Apple's side takes 5-20 minutes."
echo "    Check status: App Store Connect > Bored Phone > TestFlight"
