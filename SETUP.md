# まもる計算 — セットアップガイド

## Step 1: Chrome で動作確認（完了可能）

```bash
cd /Users/maya2018/Downloads/hoshou_shindan_app
export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
dart run build_runner build --delete-conflicting-outputs
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

または:

```bash
./scripts/run_android.sh run
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
| アプリ名「まもる計算」 | Android / iOS / Web / macOS |
| カスタムアイコン（紺×青） | `tools/generate_icons.py` で再生成可 |
| 免責文の強化 | 結果画面・設定画面に反映 |
| バンドル ID | `com.hoshou.shindan`（Android / macOS） |

アイコン再生成:

```bash
python3 tools/generate_icons.py
```

---

## Step 4: 主要機能（実施済み）

| 機能 | 説明 |
|------|------|
| **診断履歴** | Hive（AES 暗号化）で端末内に最大20件保存 |
| **結果ダッシュボード** | 費目別内訳グラフ・不足額表示 |
| **PDF / JSON エクスポート** | 診断結果の共有・バックアップ |
| **教育方針シナリオ比較** | 公立・私立などの不足額差を確認 |
| **ホーム画面ウィジェット** | iOS / Android で不足額を表示 |
| **年次リマインダー** | 再診断を促すローカル通知 |

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

---

## Step 5: 実機確認（次の作業）

### Android 実機

1. スマホで **USB デバッグ** を ON
2. USB 接続後:

```bash
adb devices
./scripts/run_android.sh run
```

または APK を直接インストール:

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### iOS 実機（要 Xcode）

1. App Store から **Xcode** をインストール
2. `ios/Runner.xcworkspace` を開き、Signing を設定
3. 実機ビルド → **MamoruHomeWidgetExtension** の Widget 追加を確認

詳細: `docs/DEVICE_TESTING.md` / `docs/hoshou_shindan_app/ios.md`
