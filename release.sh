#!/bin/bash
# Builds a release and prepares the files for the public GitHub release repository.
#   bash release.sh 0.2.0 "What's new in one line"
# Output goes to release/<version>/ : the zip, and latest.json to copy into the release repository.
# Nothing is uploaded by this script. You publish with GitHub Desktop.
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${1:?Give the version, e.g. 0.2.0}"
NOTES="${2:-}"
case "$VERSION" in
  [0-9]*.[0-9]*|[0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "Version must look like 0.2.0" >&2; exit 1 ;;
esac

# Set the version the app reports, then build and test.
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" Info.plist
SWIFT_EXTRA="-disable-sandbox" bash build.sh

OUT="release/$VERSION"
rm -rf "$OUT"; mkdir -p "$OUT"
ZIP="$OUT/StudySpaces-$VERSION.zip"
(cd build && ditto -c -k --keepParent "Study Spaces.app" "../$ZIP")

REPO="asherlwilson07-svg/study-spaces-releases"
DOWNLOAD="https://github.com/$REPO/releases/download/v$VERSION/StudySpaces-$VERSION.zip"
python3 - "$VERSION" "$DOWNLOAD" "$NOTES" "$OUT/latest.json" <<'EOF'
import json, sys
version, download, notes, path = sys.argv[1:5]
data = {"version": version, "download": download}
if notes:
    data["notes"] = notes
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
EOF

echo
echo "Release ready in $OUT"
echo "  zip:          $ZIP"
echo "  version file: $OUT/latest.json (copy to the release repository as latest.json)"
