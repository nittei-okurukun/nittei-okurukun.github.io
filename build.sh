#!/bin/zsh
# 日程送るくん を .app にビルドする
set -e
cd "$(dirname "$0")"

swift build -c release

APP="dist/日程送るくん.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
cp .build/release/NitteiOkurikun "$APP/Contents/MacOS/NitteiOkurikun"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"

echo "ビルド完了: $APP"
