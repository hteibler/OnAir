#!/bin/bash
# Increments CFBundleShortVersionString by 0.1 on every Release build.
# Debug builds are left untouched so day-to-day development does not churn the version.
set -euo pipefail

if [ "${CONFIGURATION:-}" != "Release" ]; then
    echo "OnAir version bump skipped (CONFIGURATION=${CONFIGURATION:-unset})"
    exit 0
fi

PLIST="${SRCROOT}/OnAir/Info.plist"
PLISTBUDDY="/usr/libexec/PlistBuddy"

current=$("${PLISTBUDDY}" -c "Print :CFBundleShortVersionString" "${PLIST}")
next=$(awk -v v="${current}" 'BEGIN { printf "%.1f", v + 0.1 }')

"${PLISTBUDDY}" -c "Set :CFBundleShortVersionString ${next}" "${PLIST}"

build=$("${PLISTBUDDY}" -c "Print :CFBundleVersion" "${PLIST}")
"${PLISTBUDDY}" -c "Set :CFBundleVersion $((build + 1))" "${PLIST}"

echo "OnAir version: ${current} -> ${next} (build $((build + 1)))"
