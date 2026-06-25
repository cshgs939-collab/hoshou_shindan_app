# iPhone で Web 版を使う

Android 端末がなくても、**iPhone の Safari** から同じ機能の大半を使えます。

---

## 最短手順（Mac + iPhone 同一 Wi‑Fi）

### 1. Mac で Web サーバーを起動

```bash
cd /Users/maya2018/Downloads/hoshou_shindan_app
./scripts/serve_web.sh
```

表示例:

```
Mac ブラウザ:  http://localhost:8081
iPhone Safari: http://192.168.x.x:8081
```

### 2. iPhone の Safari で URL を開く

- Mac と **同じ Wi‑Fi** に接続
- 表示された `http://192.168.x.x:8081` を iPhone Safari に入力

### 3. ホーム画面に追加（任意）

Safari → 共有ボタン → **ホーム画面に追加**

アプリ風の Web 版として起動できます（PWA）。

---

## Web 版の見た目

- 画面上部に **「Web版」** バッジ付きヘッダー
- PC ブラウザでは中央にスマホ幅のカラム表示
- iPhone では画面幅いっぱいに自然に表示

---

## Web 版で使える機能

| 機能 | Web |
|------|-----|
| 診断入力・計算 | ✅ |
| 結果ダッシュボード | ✅ |
| 履歴保存（ブラウザ内） | ✅ |
| シナリオ比較 | ✅ |
| JSON エクスポート | ✅ |
| PDF エクスポート | ⚠️ ブラウザ依存 |
| プッシュ通知 | ❌ |
| ホーム画面ウィジェット | ❌ |

---

## GitHub Release の Web zip

Release の `_web_v1.0.0.zip` を解凍し、任意の Web サーバーに配置しても利用できます。

---

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| iPhone から開けない | 同じ Wi‑Fi か確認 / Mac のファイアウォールを確認 |
| 真っ白な画面 | `./scripts/serve_web.sh` で再ビルド |
| データが消えた | ブラウザのサイトデータ削除で消えます（端末内保存） |

---

## iOS ネイティブアプリについて

App Store 版・ウィジェット・通知には **Xcode** が必要です。  
手順: `docs/IOS_SETUP.md`
