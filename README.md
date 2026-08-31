# 日程送るくん

テキスト入力中にホットキー（デフォルト **control + ⌘ + N**）を押すとカレンダーの小窓が開き、
候補日時を選んでそのまま相手に送れる文面を作成・貼り付けできる macOS メニューバーアプリ。

UIUX の参考: https://shirasaka.tv/ikano/

## 出力例

```
以下の日程でご予定はいかがでしょうか。
8月31日（月）　9:00〜12:00,14:00〜15:00
9月1日（火）　12:00〜13:00
9月10日（木）　9:30〜18:30
```

- 冒頭に「以下の日程でご予定はいかがでしょうか。」が自動で入る
- 日ごとに自動で改行、曜日つき
- 同じ日の複数時間帯は「,」区切りで1行にまとまる

## 使い方

1. メールやSlackなどのテキスト入力欄にカーソルを置いて control + ⌘（command）+ N（Nは日程 = Nittei のN）
2. カレンダーで日付をクリック（今日の週から4週間・日曜始まりで表示。過去日は選択不可）
3. 時間チップで「開始」→「終了」の順にクリックで1枠追加（複数日・複数枠OK）
4. **コピーする** を押すと、クリップボードにコピーされ、元のアプリに自動で貼り付く

- テキスト入力欄にフォーカスがない時のホットキーは奪わず、そのままアプリに渡す
- 他のアプリをクリックしてもパネルは閉じず、選択は保持される。
  閉じるのは「コピーする」か Esc のときだけ。貼り付け先は最後にいたアプリに追従
- リセットするで選択をクリア
- ライト/ダークモードに自動追従
- メニューバーのカレンダーアイコンからも開ける

## 設定

メニューバーアイコン → **設定…** から:

- **ホットキーの変更** — ⌘ か ⌃ を含む任意の組み合わせを録音して設定
- **ログイン時に自動起動**
- **アクセシビリティ権限**の状態確認と許可

初回起動時はこの設定画面がオンボーディングとして自動で開きます。

## 必要な権限

**アクセシビリティ**のみ（システム設定 → プライバシーとセキュリティ → アクセシビリティ）。

- ホットキーの監視と「入力欄にフォーカスがあるか」の判定
- 元のアプリへの自動貼り付け（⌘V 送信)

に使用します。すべての処理は Mac の中だけで完結し、ネットワーク通信は行いません。

## ビルド & インストール

```sh
./build.sh                             # dist/日程送るくん.app ができる
cp -R dist/日程送るくん.app /Applications/
open /Applications/日程送るくん.app
```

署名は自己署名証明書「NitteiOkurikun Dev」で固定しているため、リビルドしてもアクセシビリティ許可は保持されます（証明書がないマシンでは ad-hoc 署名にフォールバックし、その場合はリビルド毎に再許可が必要:
`tccutil reset Accessibility jp.teamx.nittei-okurikun` → アプリ再起動 → 再許可）。

### アプリアイコンの差し替え

1024x1024 の PNG を用意して:

```sh
./scripts/png2icns.sh path/to/icon-1024.png && ./build.sh
```

## 配布

### 無料配布（Apple Developer Program 不要）

```sh
./scripts/package.sh        # dist/nittei-okurukun.zip ができる
```

これを GitHub Releases にアップロードして配布します。無署名のため、
ダウンロードした人は初回起動時に Gatekeeper に止められます。案内する起動方法は:

- **かんたん**: インストーラを1行で実行（ダウンロード〜隔離解除〜起動まで自動）

  ```sh
  curl -fsSL https://raw.githubusercontent.com/takumitakatani/nittei-okurukun/main/scripts/install.sh | zsh
  ```

- **手動**: zip を展開して /Applications へ → 起動が拒否されたら
  システム設定 → プライバシーとセキュリティ → 「このまま開く」

### 公証つき配布（将来、要 Apple Developer Program・年99ドル）

Gatekeeper の警告なしで配布したくなったら、Developer ID 署名 → 公証 → DMG 化まで一括:

```sh
SIGN_ID="Developer ID Application: Your Name (TEAMID)" ./scripts/release.sh
```

詳細な事前準備は [scripts/release.sh](scripts/release.sh) のコメント参照。

## 構成

- `Sources/NitteiOkurikun/ScheduleModel.swift` — 選択状態と文面生成
- `Sources/NitteiOkurikun/ContentView.swift` — カレンダー / 時間チップ / プレビューの SwiftUI
- `Sources/NitteiOkurikun/HotKeyTap.swift` — ホットキーのイベントタップと入力欄判定、⌘V 送信
- `Sources/NitteiOkurikun/PanelController.swift` — フローティングパネル
- `Sources/NitteiOkurikun/SettingsView.swift` / `SettingsController.swift` — 設定・オンボーディング
- `Sources/NitteiOkurikun/Prefs.swift` — ホットキー等の永続化
- `Sources/NitteiOkurikun/AppDelegate.swift` — メニューバー・コピー&ペースト
- `docs/index.html` — 紹介ページ（GitHub Pages 用）

デバッグ用フラグ: `--show`（起動時にパネルを開く）、
`--snapshot <path>` / `--snapshot-settings <path>`（UIをPNG出力して終了、`--dark` / `--light` 併用可）

## ライセンス

MIT — [LICENSE](LICENSE)
