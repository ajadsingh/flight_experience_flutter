#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-./flight_experience_app}"
SOURCE="$(cd "$(dirname "$0")" && pwd)"

command -v flutter >/dev/null 2>&1 || { echo 'Flutter is not on PATH.' >&2; exit 1; }

if [[ -e "$TARGET" && -n "$(ls -A "$TARGET" 2>/dev/null)" ]]; then
  echo "Target exists and is not empty: $TARGET" >&2
  exit 1
fi
mkdir -p "$TARGET"

flutter create --platforms=android --project-name flight_experience "$TARGET"

cp -f "$SOURCE/pubspec.yaml" "$TARGET/pubspec.yaml"
cp -f "$SOURCE/analysis_options.yaml" "$TARGET/analysis_options.yaml"
rm -rf "$TARGET/lib" "$TARGET/assets" "$TARGET/test"
cp -R "$SOURCE/lib" "$TARGET/lib"
cp -R "$SOURCE/assets" "$TARGET/assets"
cp -R "$SOURCE/test" "$TARGET/test"
cp -f "$SOURCE/README.md" "$TARGET/README.md"

MANIFEST="$TARGET/android/app/src/main/AndroidManifest.xml"
if ! grep -q 'android.permission.ACCESS_FINE_LOCATION' "$MANIFEST"; then
  python3 - "$MANIFEST" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
marker = '<manifest'
idx = s.find('>', s.find(marker))
insert = '\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />\n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />'
p.write_text(s[:idx+1] + insert + s[idx+1:])
PY
fi

cd "$TARGET"
flutter pub get

echo
printf 'Flight Experience app created at: %s\n' "$TARGET"
printf 'Run: cd %s && flutter analyze && flutter test && flutter run\n' "$TARGET"
