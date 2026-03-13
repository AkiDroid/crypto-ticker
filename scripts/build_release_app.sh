#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="${APP_NAME:-CryptoTicker}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-CryptoTickerApp}"
BUNDLE_ID="${APP_BUNDLE_ID:-com.mqy.crypto-ticker}"
APP_VERSION="${APP_VERSION:-0.1.0-dev}"
BUILD_VERSION="${BUILD_VERSION:-$APP_VERSION}"
ARCHIVE_SUFFIX="${1:-macos-$(uname -m)}"
SIGN_IDENTITY="${APPLE_SIGN_IDENTITY:--}"

DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
TEMPLATE_PATH="$ROOT_DIR/packaging/Info.plist.template"
PLIST_PATH="$CONTENTS_DIR/Info.plist"
ZIP_PATH="$DIST_DIR/${APP_NAME}-${ARCHIVE_SUFFIX}.zip"
CHECKSUM_PATH="$DIST_DIR/${APP_NAME}-${ARCHIVE_SUFFIX}.sha256"

echo "==> 构建 release 可执行文件"
swift build -c release --product "$EXECUTABLE_NAME" --package-path "$ROOT_DIR"
BIN_DIR="$(swift build -c release --product "$EXECUTABLE_NAME" --package-path "$ROOT_DIR" --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/$EXECUTABLE_NAME"

if [[ ! -f "$EXECUTABLE_PATH" ]]; then
  echo "未找到可执行文件: $EXECUTABLE_PATH" >&2
  exit 1
fi

echo "==> 组装 .app"
rm -rf "$APP_DIR" "$ZIP_PATH" "$CHECKSUM_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$EXECUTABLE_PATH" "$MACOS_DIR/$EXECUTABLE_NAME"
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"

sed \
  -e "s#__APP_NAME__#$APP_NAME#g" \
  -e "s#__EXECUTABLE_NAME__#$EXECUTABLE_NAME#g" \
  -e "s#__BUNDLE_ID__#$BUNDLE_ID#g" \
  -e "s#__APP_VERSION__#$APP_VERSION#g" \
  -e "s#__BUILD_VERSION__#$BUILD_VERSION#g" \
  "$TEMPLATE_PATH" > "$PLIST_PATH"

echo "==> 签名 .app"
if [[ "$SIGN_IDENTITY" == "-" ]]; then
  codesign --force --deep --sign - "$APP_DIR"
else
  codesign --force --deep --options runtime --sign "$SIGN_IDENTITY" "$APP_DIR"
fi

echo "==> 压缩发布产物"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

echo "==> 完成"
echo "App: $APP_DIR"
echo "Zip: $ZIP_PATH"
echo "SHA256: $CHECKSUM_PATH"
