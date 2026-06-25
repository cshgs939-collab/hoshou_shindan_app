# まもる計算

家族を守る保障額シミュレーター（Flutter 3.x / iOS・Android・Web）

家族構成・収入・支出・既存保障から必要保障額を試算し、不足額を可視化します。保険販売・勧誘ではなく、参考用の簡易診断ツールです。

## 起動

```bash
cd /Users/maya2018/Downloads/hoshou_shindan_app
/Users/maya2018/flutter/bin/flutter pub get
/Users/maya2018/flutter/bin/dart run build_runner build --delete-conflicting-outputs
/Users/maya2018/flutter/bin/flutter run
```

## ドキュメント

| 内容 | 場所 |
|---|---|
| プロジェクト索引 | [docs/hoshou_shindan_app/INDEX.md](../docs/hoshou_shindan_app/INDEX.md) |
| 名称・系譜 | [docs/hoshou_shindan_app/legacy.md](../docs/hoshou_shindan_app/legacy.md) |
| セットアップ | [SETUP.md](./SETUP.md) |
| 実機確認 | [docs/DEVICE_TESTING.md](./docs/DEVICE_TESTING.md) |

## よく使うコマンド

```bash
flutter analyze
flutter test
flutter build web --release
./scripts/run_android.sh run
./scripts/serve_web.sh
```
