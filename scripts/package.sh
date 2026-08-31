#!/bin/zsh
# 無料配布用: ビルドして GitHub Releases に上げる zip を作る
# 使い方: ./scripts/package.sh
set -e
cd "$(dirname "$0")/.."

./build.sh
ZIP="dist/nittei-okurikun.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "dist/日程送るくん.app" "$ZIP"
echo "作成完了: $ZIP（GitHub Releases にアップロードしてください）"
