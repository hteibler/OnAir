#!/bin/bash
# Archive, notarize and staple OnAir for Developer ID distribution.
#
# One-time setup — store an App Store Connect API key (or Apple ID) in the
# keychain under a profile name:
#   xcrun notarytool store-credentials OnAir-notary \
#       --key ~/private_keys/AuthKey_XXXX.p8 --key-id XXXX --issuer <issuer-uuid>
#
# Then: Scripts/notarize.sh
set -euo pipefail

PROFILE="${NOTARY_PROFILE:-OnAir-notary}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${ROOT}/build"
ARCHIVE="${BUILD}/OnAir.xcarchive"
APP="${ARCHIVE}/Products/Applications/OnAir.app"
ZIP="${BUILD}/OnAir.zip"

cd "$ROOT"
xcodegen generate
rm -rf "$BUILD"
mkdir -p "$BUILD"

echo "▸ Archiving (Release, Developer ID)…"
xcodebuild -project OnAir.xcodeproj -scheme OnAir -configuration Release \
    -archivePath "$ARCHIVE" archive

echo "▸ Verifying signature…"
codesign --verify --strict --deep --verbose=2 "$APP"
codesign -dvv "$APP" 2>&1 | grep -E 'Authority=Developer ID|flags=.*runtime|Timestamp='

echo "▸ Zipping for submission…"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "▸ Submitting to Apple (waits for result)…"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

echo "▸ Stapling…"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl -a -vvv -t exec "$APP"

echo "▸ Repackaging stapled app…"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "✓ Done: $ZIP"
