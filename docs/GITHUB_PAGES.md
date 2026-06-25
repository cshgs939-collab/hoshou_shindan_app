# GitHub Pages でまもる計算を公開する（日本語ガイド）

外出先の iPhone / Android からも使える **インターネット公開 URL** を用意する手順です。  
同一 Wi‑Fi 限定のローカル QR とは別物です。

---

## これで何ができるか

| 項目 | 内容 |
|------|------|
| 公開 URL | `https://cshgs939-collab.github.io/hoshou_shindan_app/` |
| 使える場所 | 自宅・外出先・モバイル回線どこからでも |
| データ | 端末のブラウザ内のみ（サーバーには送信しない） |
| 更新 | `main` ブランチへ push すると自動再デプロイ |

---

## 初回セットアップ（リポジトリ管理者向け）

### 1. GitHub Pages を有効化

1. ブラウザでリポジトリを開く  
   https://github.com/cshgs939-collab/hoshou_shindan_app
2. **Settings** → 左メニュー **Pages**
3. **Build and deployment** で次を設定  
   - **Source:** GitHub Actions  
   （「Deploy from a branch」ではなく **GitHub Actions** を選ぶ）
4. 保存後、**Actions** タブを開く

> 現在 Pages API が 404 の場合、上記の有効化がまだ完了していません。

### 2. デプロイを実行

**方法 A — push で自動**

```bash
cd /Users/maya2018/Downloads/hoshou_shindan_app
git push origin main
```

**方法 B — 手動実行**

1. **Actions** → **Deploy Web**
2. **Run workflow** → **Run workflow**

### 3. 公開を確認

1. **Actions** で緑色の ✓ になるまで待つ（初回 5〜10 分程度）
2. **Settings → Pages** に表示される URL を開く  
   または直接:  
   **https://cshgs939-collab.github.io/hoshou_shindan_app/**
3. 診断画面が表示されれば成功

---

## 仕組み（ナレーション）

```
あなたの Mac
  └─ flutter build web --release
       └─ git push (main)
            └─ GitHub Actions「Deploy Web」
                 └─ build/web を GitHub Pages に配置
                      └─ 世界中から HTTPS でアクセス可能
```

- ワークフロー: `.github/workflows/deploy-web.yml`
- ビルド時に `--base-href "/hoshou_shindan_app/"` を指定（サブパス公開のため必須）
- Mac を起動したままにする必要は **ありません**

---

## スマホで使う（利用者向け）

### 手順

1. Safari / Chrome で公開 URL を開く  
   `https://cshgs939-collab.github.io/hoshou_shindan_app/`
2. **共有** → **ホーム画面に追加**
3. ホーム画面のアイコンから起動（アプリ風）

### QR コード

公開 URL 用 QR を生成:

```bash
cd /Users/maya2018/Downloads/hoshou_shindan_app
./scripts/share_qr_pages.sh
```

- QR ページ: `outputs/mamoru_qr_pages.html`
- QR 画像: `outputs/mamoru_qr_pages.png`
- **同一 Wi‑Fi 不要** — 外出先でも読み取れます

---

## ローカル QR との違い

| | ローカル（`share_qr.sh`） | GitHub Pages（`share_qr_pages.sh`） |
|---|---|---|
| URL 例 | `http://192.168.x.x:8081` | `https://cshgs939-collab.github.io/...` |
| 外出先 | ❌ 使えない | ✅ 使える |
| Mac 起動 | 必要 | 不要 |
| 用途 | 自宅・開発確認 | 家族共有・本番 |

---

## 更新の流れ

1. コードを修正
2. `flutter test` で確認
3. `git commit` → `git push origin main`
4. GitHub Actions が自動ビルド（数分）
5. スマホで **再読み込み**（キャッシュが残る場合は Safari のサイトデータ削除）

---

## トラブルシューティング

| 症状 | 原因と対処 |
|------|-----------|
| **404 Not Found** | Pages 未設定 → Settings → Pages → Source を **GitHub Actions** に |
| **真っ白な画面** | デプロイ直後 → 数分待って再読み込み |
| **古い画面のまま** | ブラウザキャッシュ → スーパーリロード / サイトデータ削除 |
| **Actions が失敗** | Actions ログを確認。`build_runner` や Flutter ビルドエラーを修正 |
| **アセットが 404** | `base-href` 不一致 → ワークフローの `--base-href "/hoshou_shindan_app/"` を確認 |
| **Google 検索に出ない** | 正常。URL を直接入力するか QR を使う |

---

## セキュリティ・プライバシー

- 入力データは **利用者の端末内** に保存（Hive / SharedPreferences）
- GitHub Pages は **静的ファイル配信のみ** — 入力内容は GitHub に送られません
- 公開 URL は **誰でもアクセス可能** ですが、個人の診断データは URL からは見えません
- 詳細: [PRIVACY_POLICY.md](./PRIVACY_POLICY.md)

---

## 関連ドキュメント

- [WEB_IPHONE.md](./WEB_IPHONE.md) — iPhone で Web 版を使う
- [DEVICE_TESTING.md](./DEVICE_TESTING.md) — 実機確認
- ローカル起動: `./scripts/serve_web.sh`
- ローカル QR: `./scripts/share_qr.sh`

---

## よくある質問

**Q. 無料ですか？**  
A. GitHub Pages はパブリックリポジトリなら無料です。

**Q. 独自ドメインは使えますか？**  
A. Settings → Pages → Custom domain で設定可能です。

**Q. App Store 版とどちらがよい？**  
A. 手軽さは GitHub Pages。通知・ウィジェットが必要ならネイティブアプリ（`IOS_SETUP.md` / `ANDROID_RELEASE.md`）。
