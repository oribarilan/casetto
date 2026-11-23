#!/bin/zsh
# Archives Casterr with a fresh build number and exports it for the App Store, signed through the Apple ID that
# Xcode is signed in to (Xcode > Settings > Accounts).
#   DEVELOPMENT_TEAM=<team id> scripts/testflight.sh            archive and export locally, to check signing
#   DEVELOPMENT_TEAM=<team id> scripts/testflight.sh --upload   archive and upload to TestFlight
# The team ID comes from the command line only.
set -euo pipefail
cd "${0:A:h}/.."

: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM to your team ID}"
destination=export
[[ "${1:-}" == "--upload" ]] && destination=upload

# A build number from the clock always rises, so there's nothing to bump in the repo.
build=$(date +%Y%m%d%H%M)
out="${TMPDIR:-/tmp}/casterr-testflight/$build"
mkdir -p "$out"

xcodegen generate --quiet
echo "Archiving build $build..."
xcodebuild archive -scheme Casterr -configuration Release -destination generic/platform=iOS \
  -archivePath "$out/Casterr.xcarchive" -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" CURRENT_PROJECT_VERSION="$build" -quiet

cat > "$out/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$destination</string>
  <key>teamID</key><string>$DEVELOPMENT_TEAM</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST

echo "Exporting ($destination)..."
xcodebuild -exportArchive -archivePath "$out/Casterr.xcarchive" -exportOptionsPlist "$out/ExportOptions.plist" \
  -exportPath "$out/export" -allowProvisioningUpdates -quiet
if [[ $destination == upload ]]; then
  echo "Uploaded build $build. It shows in TestFlight after Apple processes it, usually within 30 minutes."
else
  echo "Exported build $build to $out/export. Run with --upload to send it to TestFlight."
fi
