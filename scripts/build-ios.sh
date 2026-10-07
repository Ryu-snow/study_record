#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ "$(uname -s)" != Darwin ]] || ! command -v xcodebuild >/dev/null 2>&1; then
  echo "macOS と Xcode 16 以降（iOS SDK を含む）が必要です。" >&2
  exit 1
fi

mode="${1:-simulator}"
mkdir -p build/logs
common=(-project FORMStudy.xcodeproj -scheme FORMStudy -configuration Debug)
case "$mode" in
  simulator)
    xcodebuild "${common[@]}" -sdk iphonesimulator \
      -destination 'generic/platform=iOS Simulator' \
      -derivedDataPath build/SimulatorDerivedData CODE_SIGNING_ALLOWED=NO \
      build 2>&1 | tee build/logs/simulator.log
    ;;
  device)
    team="${DEVELOPMENT_TEAM:-D9K33N34XD}"
    destination='generic/platform=iOS'
    if [[ -n "${DEVICE_UDID:-}" ]]; then
      destination="platform=iOS,id=$DEVICE_UDID"
    fi
    xcodebuild "${common[@]}" -sdk iphoneos -destination "$destination" \
      -derivedDataPath build/DeviceDerivedData \
      -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
      "DEVELOPMENT_TEAM=$team" CODE_SIGN_STYLE=Automatic \
      build 2>&1 | tee build/logs/device.log
    app=build/DeviceDerivedData/Build/Products/Debug-iphoneos/FORMStudy.app
    extension="$app/PlugIns/FORMStudyWidget.appex"
    test -d "$extension"
    test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist")" = jp.ryukawasaki.formstudy
    test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$extension/Info.plist")" = jp.ryukawasaki.formstudy.widget
    test "$(/usr/libexec/PlistBuddy -c 'Print :NSSupportsLiveActivities' "$app/Info.plist")" = true
    test "$(/usr/libexec/PlistBuddy -c 'Print :NSExtension:NSExtensionPointIdentifier' "$extension/Info.plist")" = com.apple.widgetkit-extension
    codesign --verify --strict --verbose=2 "$extension"
    codesign --verify --strict --verbose=2 "$app"
    echo "署名済みアプリ: $PROJECT_ROOT/$app"
    ;;
  *)
    echo "Usage: bash scripts/build-ios.sh [simulator|device]" >&2
    exit 2
    ;;
esac
