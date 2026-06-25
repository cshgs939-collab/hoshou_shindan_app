# iOS / Xcode セットアップガイド

## 現在の環境（2026-06-25）

| 項目 | 状態 |
|------|------|
| Xcode（フル版） | ❌ 未インストール |
| Command Line Tools | ✅ `/Library/Developer/CommandLineTools` |
| CocoaPods | ❌ 未インストール |
| Flutter iOS ビルド | ❌ Xcode 必須 |

> Flutter の iOS ビルド・シミュレータ・実機デプロイには **App Store 版 Xcode** が必要です。Command Line Tools のみでは不十分です。

---

## Step 1: Xcode をインストール

1. Mac App Store で **Xcode** を検索してインストール（約 12GB、時間がかかります）
2. 初回起動してライセンスに同意

---

## Step 2: コマンドラインツールを Xcode に切り替え

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcodebuild -version
```

`xcodebuild -version` で Xcode のバージョンが表示されれば OK です。

---

## Step 3: CocoaPods をインストール

```bash
sudo gem install cocoapods
pod --version
```

Homebrew 経由の場合:

```bash
brew install cocoapods
```

---

## Step 4: プロジェクトの iOS 依存関係

```bash
cd /Users/maya2018/Downloads/hoshou_shindan_app/ios
pod install
cd ..
```

---

## Step 5: シミュレータで実行

```bash
export PATH="$HOME/flutter/bin:$PATH"
open -a Simulator
flutter devices
flutter run -d ios
```

---

## Step 6: iPhone 実機で実行

1. iPhone を USB 接続 → 「このコンピュータを信頼する」をタップ
2. Xcode → Settings → Accounts で Apple ID を追加（無料の Personal Team で可）
3. `ios/Runner.xcworkspace` を Xcode で開く
4. **Runner** と **MamoruHomeWidgetExtension** の Signing で Team を選択
5. ターミナル:

```bash
flutter devices
flutter run -d <iPhone の device ID>
```

6. iPhone: 設定 → 一般 → VPNとデバイス管理 → 開発者アプリを信頼

---

## Step 7: ホームウィジェットの確認

1. ホーム画面を長押し → ウィジェットを追加
2. **まもる計算** のウィジェットを配置
3. アプリで診断実行後、不足額がウィジェットに反映されることを確認

App Group ID: `group.mamoru.keisan.widget`

---

## よくあるエラー

| 症状 | 対処 |
|------|------|
| `Xcode installation is incomplete` | App Store から Xcode をインストール |
| `CocoaPods not installed` | `sudo gem install cocoapods` |
| `Signing for Runner requires a development team` | Xcode で Team を選択 |
| `pod install` 失敗 | `pod repo update` 後に再実行 |
| 実機にアプリが起動しない | VPNとデバイス管理で信頼 |

---

## 確認コマンド

```bash
flutter doctor -v
xcode-select -p
pod --version
ls ios/Podfile.lock
```

すべて ✅ になれば iOS 開発の準備完了です。
