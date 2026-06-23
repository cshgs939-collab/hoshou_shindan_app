# 必要保障額診断 — セットアップガイド

## Step 1: Chrome で動作確認（完了可能）

```bash
cd /Users/maya2018/Downloads/hoshou_shindan_app
export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
flutter run -d chrome
```

ブラウザで `http://localhost:<port>` が開きます。

---

## Step 2: iOS / Android シミュレータ・実機

### 環境確認

```bash
flutter doctor -v
flutter devices
```

### iOS / macOS（Xcode が必要）

1. App Store から **Xcode** をインストール
2. 初回セットアップ:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo gem install cocoapods
```

3. 実行:

```bash
cd ios && pod install && cd ..
flutter run -d ios      # iPhone シミュレータ
flutter run -d macos    # macOS アプリ
```

### Android（Android Studio が必要）

1. [Android Studio](https://developer.android.com/studio) をインストール
2. SDK Manager で Android SDK / Emulator をセットアップ
3. ライセンス同意:

```bash
flutter doctor --android-licenses
```

4. エミュレータ起動後:

```bash
flutter emulators
flutter emulators --launch <emulator_id>
flutter run -d android
```

### ビルドのみ確認（実機なし）

```bash
flutter build apk --debug     # Android
flutter build ios --no-codesign  # iOS（Xcode 必要）
flutter build web             # Web
```

---

## Step 3: アイコン・名称・免責文（実施済み）

| 項目 | 状態 |
|------|------|
| アプリ名「必要保障額診断」 | Android / iOS / Web / macOS |
| カスタムアイコン（紺×青） | `tools/generate_icons.py` で再生成可 |
| 免責文の強化 | 結果画面・共有テキストに反映 |
| バンドル ID | `com.hoshou.shindan`（Android / macOS） |

アイコン再生成:

```bash
python3 tools/generate_icons.py
```

---

## Step 4: 追加機能（実施済み）

| 機能 | 説明 |
|------|------|
| **結果の保存** | `shared_preferences` で端末内に前回結果を保存 |
| **前回結果の表示** | ホーム画面から再表示・削除可能 |
| **結果の共有** | `share_plus` でテキスト共有（PDF ではなくテキスト） |
| **シナリオ比較** | 進学タイプ・雇用形態を変えた試算を並べて表示 |

---

## よく使うコマンド

```bash
flutter analyze          # 静的解析
flutter test             # テスト
flutter pub get          # 依存関係更新
flutter clean && flutter pub get  # キャッシュクリア
```

---

## ストア公開前チェックリスト

- [ ] プライバシーポリシー（端末内完結・外部送信なし）
- [ ] スクリーンショット（ホーム / 入力 / 結果 / 比較）
- [ ] ストア説明文に「簡易試算」「勧誘なし」を明記
- [ ] iOS: Apple Developer Program / 署名
- [ ] Android: リリース用 keystore 作成
