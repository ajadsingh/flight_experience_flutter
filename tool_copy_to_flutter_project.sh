#!/usr/bin/env bash
set -euo pipefail
TARGET="${1:-}"
if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
  echo "Usage: ./tool_copy_to_flutter_project.sh /path/to/flutter/project"
  exit 1
fi
SOURCE="$(cd "$(dirname "$0")" && pwd)"
cp -f "$SOURCE/pubspec.yaml" "$TARGET/pubspec.yaml"
cp -f "$SOURCE/analysis_options.yaml" "$TARGET/analysis_options.yaml"
rm -rf "$TARGET/lib" "$TARGET/assets" "$TARGET/test"
cp -R "$SOURCE/lib" "$TARGET/lib"
cp -R "$SOURCE/assets" "$TARGET/assets"
cp -R "$SOURCE/test" "$TARGET/test"
cp -f "$SOURCE/README.md" "$TARGET/README.md"
echo "Copied Flight Experience source into $TARGET"
echo "Next: add the Android permissions from README.md, then run flutter pub get && flutter analyze && flutter test"
