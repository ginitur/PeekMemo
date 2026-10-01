#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="PeekMemo"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DIST="$ROOT/dist"
APP="$DIST/${APP_NAME}.app"
ZIP="$DIST/PeekMemo-macOS-${VERSION}.zip"

echo "→ Building $APP_NAME (release)"
swift build -c release --product "$APP_NAME"

BIN="$(swift build -c release --product "$APP_NAME" --show-bin-path)/$APP_NAME"
if [[ ! -x "$BIN" ]]; then
  echo "error: expected executable at $BIN" >&2
  exit 1
fi

echo "→ Assembling $APP"
rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
cp "$ROOT/Sources/PeekMemo/Resources/Info.plist" "$APP/Contents/Info.plist"
ICON="$ROOT/Brand/AppIcon.icns"
if [[ ! -f "$ICON" ]]; then
  echo "error: missing $ICON — run scripts/make-icons.py" >&2
  exit 1
fi
cp "$ICON" "$APP/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$APP/Contents/PkgInfo"
chmod +x "$APP/Contents/MacOS/$APP_NAME"

if find "$APP" \( -name '*.sqlite' -o -name '*.sqlite-shm' -o -name '*.sqlite-wal' -o -name 'settings.json' \) | grep -q .; then
  echo "error: the app bundle contains user data" >&2
  exit 1
fi

if command -v codesign >/dev/null; then
  echo "→ Ad-hoc codesign (not Developer ID, not notarized)"
  codesign --force --deep --sign - "$APP"
fi

echo "→ Zipping $ZIP"
(
  cd "$DIST"
  ditto -c -k --keepParent "${APP_NAME}.app" "$(basename "$ZIP")"
)

echo "Built:"
echo "  $APP"
echo "  $ZIP"
