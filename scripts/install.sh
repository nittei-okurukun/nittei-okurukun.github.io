#!/bin/zsh
# 日程送るくん インストーラ（無署名配布のため、Gatekeeperの隔離属性を外してインストールする）
#
# 使い方:
#   curl -fsSL https://raw.githubusercontent.com/nittei-okurukun/nittei-okurukun.github.io/main/scripts/install.sh | zsh
set -e

REPO="nittei-okurukun/nittei-okurukun.github.io"
URL="https://github.com/$REPO/releases/latest/download/nittei-okurukun.zip"
TMP=$(mktemp -d)

echo "ダウンロード中…"
curl -fsSL "$URL" -o "$TMP/app.zip"
ditto -x -k "$TMP/app.zip" "$TMP"

echo "/Applications にインストール中…"
osascript -e 'tell application "日程送るくん" to quit' >/dev/null 2>&1 || true
pkill -x NitteiOkurikun 2>/dev/null || true
sleep 1
rm -rf "/Applications/日程送るくん.app"
mv "$TMP/日程送るくん.app" /Applications/
xattr -dr com.apple.quarantine "/Applications/日程送るくん.app" 2>/dev/null || true

open "/Applications/日程送るくん.app"
echo "インストール完了。初回はアクセシビリティの許可をお願いします（設定画面が開きます）。"
