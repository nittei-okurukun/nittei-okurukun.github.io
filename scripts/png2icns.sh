#!/bin/zsh
# 1024x1024 の PNG からアプリアイコン (.icns) を作る
# 使い方: ./scripts/png2icns.sh path/to/icon-1024.png
set -e
cd "$(dirname "$0")/.."

SRC="$1"
if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "使い方: ./scripts/png2icns.sh <1024x1024のPNG>" >&2
  exit 1
fi

ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"
for px in 16 32 128 256 512; do
  sips -z $px $px "$SRC" --out "$ICONSET/icon_${px}x${px}.png" >/dev/null
  px2=$((px * 2))
  sips -z $px2 $px2 "$SRC" --out "$ICONSET/icon_${px}x${px}@2x.png" >/dev/null
done
mkdir -p Resources
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
echo "作成完了: Resources/AppIcon.icns（./build.sh で反映されます）"
