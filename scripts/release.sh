#!/bin/zsh
# 配布用ビルド: Developer ID 署名 → 公証 → DMG 作成
#
# 事前準備（一度だけ）:
#   1. Apple Developer Program に登録し、Xcode で Developer ID Application 証明書を取得
#   2. App用パスワードを作成し、公証用プロファイルを保存:
#      xcrun notarytool store-credentials "nittei-okurikun" \
#        --apple-id <AppleID> --team-id <TeamID> --password <App用パスワード>
#
# 使い方:
#   SIGN_ID="Developer ID Application: Your Name (TEAMID)" ./scripts/release.sh
set -e
cd "$(dirname "$0")/.."

if [[ -z "$SIGN_ID" ]]; then
  echo "SIGN_ID 環境変数に Developer ID Application 証明書名を指定してください" >&2
  echo '例: SIGN_ID="Developer ID Application: Taro Yamada (ABCDE12345)" ./scripts/release.sh' >&2
  exit 1
fi
PROFILE="${NOTARY_PROFILE:-nittei-okurikun}"

./build.sh
APP="dist/日程送るくん.app"

echo "== Developer ID で署名 =="
codesign --force --deep --options runtime --sign "$SIGN_ID" "$APP"
codesign --verify --strict "$APP"

echo "== DMG 作成 =="
DMG="dist/日程送るくん.dmg"
rm -f "$DMG"
STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "日程送るくん" -srcfolder "$STAGE" -ov -format UDZO "$DMG"

echo "== 公証（数分かかります）=="
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"

echo "完了: $DMG（このファイルをそのまま配布できます）"
