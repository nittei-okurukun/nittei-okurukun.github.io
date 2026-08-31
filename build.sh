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
# 自己署名証明書があればそれで署名（署名が固定され、アクセシビリティ許可が保持される）
if security find-identity -p codesigning -v 2>/dev/null | grep -q "NitteiOkurikun Dev"; then
  codesign --force --sign "NitteiOkurikun Dev" "$APP"
  echo "署名: NitteiOkurikun Dev（固定署名）"
else
  codesign --force --sign - "$APP"
  echo "署名: ad-hoc（リビルド毎にアクセシビリティ再許可が必要）"
fi

echo "ビルド完了: $APP"
