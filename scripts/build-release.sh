#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="PeekMemo"
DIST="$ROOT/dist"
APP="$DIST/${APP_NAME}.app"
EXECUTABLE_NAME="$APP_NAME"

echo "→ Building $APP_NAME (release)"
swift build -c release --product "$APP_NAME"

BIN="$(swift build -c release --product "$APP_NAME" --show-bin-path)/$EXECUTABLE_NAME"
if [[ ! -x "$BIN" ]]; then
  echo "error: expected executable at $BIN" >&2
  exit 1
fi

echo "→ Assembling $APP"
rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/$EXECUTABLE_NAME"
cp "$ROOT/Sources/PeekMemo/Resources/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

if command -v codesign >/dev/null; then
  echo "→ Ad-hoc codesign (not Developer ID, not notarized)"
  codesign --force --deep --sign - "$APP"
fi

echo "→ Zipping"
(
  cd "$DIST"
  ditto -c -k --keepParent "${APP_NAME}.app" "${APP_NAME}.zip"
)

echo "Built:"
echo "  $APP"
echo "  $DIST/${APP_NAME}.zip"
