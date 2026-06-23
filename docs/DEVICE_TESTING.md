# 実機確認ガイド

## 現在の環境状態（2026-06-21 時点）

| 項目 | 状態 |
|------|------|
| Flutter 3.44.2 | ✅ |
| Android SDK 36 | ✅ セットアップ済み |
| Android エミュレータ | ✅ Pixel_7_API_35 で起動・動作確認済み |
| アプリ (com.hoshou.shindan) | ✅ エミュレータ上で診断結果画面まで確認 |
| iOS / Xcode | ❌ 未インストール（App Store から Xcode が必要） |
| 物理 Android 端末 | 未接続（USB 接続で確認可能） |

---

## Android エミュレータで確認（セットアップ済み）

```bash
cd /Users/maya2018/Downloads/hoshou_shindan_app
chmod +x scripts/run_android.sh
./scripts/run_android.sh run
```

個別コマンド:

```bash
./scripts/run_android.sh emulator   # エミュレータ起動
./scripts/run_android.sh devices    # 接続デバイス一覧
./scripts/run_android.sh apk        # APK ビルド
./scripts/run_android.sh install    # 接続端末へ APK インストール
```

### 環境変数（自動設定されます）

| 変数 | パス |
|------|------|
| `JAVA_HOME` | `~/.local/jdk-17/Contents/Home` |
| `ANDROID_HOME` | `~/Library/Android/sdk` |
| Flutter | `~/flutter/bin` |

---

## 物理 Android 端末で確認

1. **スマホ側**
   - 設定 → 端末情報 → 「ビルド番号」を7回タップ（開発者向けオプション有効化）
   - 設定 → 開発者向けオプション → **USB デバッグ** を ON
   - USB ケーブルで Mac に接続
   - 「このコンピュータを許可しますか？」→ **許可**

2. **Mac 側**

```bash
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
adb devices          # 端末 ID が表示されること
./scripts/run_android.sh run
```

3. **APK を直接インストールする場合**

```bash
./scripts/run_android.sh apk
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## iPhone 実機で確認（要 Xcode）

iOS 実機確認には **App Store から Xcode をインストール** する必要があります（約 12GB、自動インストール不可）。

### 手順

1. App Store で **Xcode** をインストール
2. ターミナルで初期設定:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo gem install cocoapods
cd /Users/maya2018/Downloads/hoshou_shindan_app/ios
pod install
cd ..
```

3. iPhone を USB 接続し、iPhone 側で「このコンピュータを信頼する」を選択
4. Xcode → Settings → Accounts で Apple ID を追加（無料の Personal Team で可）
5. 実行:

```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter devices
flutter run -d <iPhone の device ID>
```

> 初回は iPhone の 設定 → 一般 → VPNとデバイス管理 から開発者アプリを信頼する必要があります。

---

## 動作確認済みスクリーンショット

エミュレータ上で以下を確認済み:

- 診断結果画面の表示
- 不足保障額・内訳グラフ・詳細カード
- アプリ名「必要保障額診断」

保存場所: `docs/android_emulator_screenshot.png`

---

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| `Unable to locate Android SDK` | `flutter config --android-sdk ~/Library/Android/sdk` |
| `Unable to locate Java` | `export JAVA_HOME=$HOME/.local/jdk-17/Contents/Home` |
| エミュレータが起動しない | `emulator -list-avds` で AVD 名を確認 |
| 実機が `adb devices` に出ない | USB デバッグ ON / ケーブル変更 / 許可ダイアログ確認 |
| iOS ビルド失敗 | Xcode 完全インストール + `pod install` |
