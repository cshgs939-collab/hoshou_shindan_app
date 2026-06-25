#!/bin/bash
# まもる計算 — GitHub Pages 公開 URL 用 QR（外出先 OK）
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

PAGES_URL="${PAGES_URL:-https://cshgs939-collab.github.io/hoshou_shindan_app/}"
OUTPUT_DIR="$PROJECT_DIR/outputs"
QR_PNG="$OUTPUT_DIR/mamoru_qr_pages.png"
QR_HTML="$OUTPUT_DIR/mamoru_qr_pages.html"

mkdir -p "$OUTPUT_DIR"

echo "GitHub Pages 用 QR を生成しています..."
encoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${PAGES_URL}'))")
curl -fsSL \
  "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=${encoded_url}" \
  -o "$QR_PNG"

cat > "$QR_HTML" <<EOF
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>まもる計算 — GitHub Pages QR</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100dvh;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: "Hiragino Sans", "Yu Gothic", sans-serif;
      background: #f0fdf4;
      color: #0f172a;
      padding: 24px;
    }
    .card {
      background: #fff;
      border: 1px solid #bbf7d0;
      border-radius: 20px;
      padding: 32px 28px;
      text-align: center;
      max-width: 420px;
      width: 100%;
      box-shadow: 0 4px 20px rgba(22, 163, 74, 0.12);
    }
    h1 { margin: 0 0 4px; font-size: 1.35rem; }
    .badge {
      display: inline-block;
      margin-bottom: 16px;
      padding: 4px 10px;
      border-radius: 999px;
      background: #dcfce7;
      color: #166534;
      font-size: 0.75rem;
      font-weight: 600;
    }
    .sub { margin: 0 0 20px; font-size: 0.875rem; color: #64748b; }
    .qr-img {
      width: 240px;
      height: 240px;
      border-radius: 12px;
      border: 1px solid #e2e8f0;
    }
    .url {
      margin-top: 20px;
      font-size: 0.8125rem;
      word-break: break-all;
      color: #16a34a;
      font-weight: 600;
    }
    .steps {
      margin-top: 20px;
      text-align: left;
      font-size: 0.8125rem;
      color: #475569;
      line-height: 1.7;
    }
    .hint {
      margin-top: 16px;
      font-size: 0.75rem;
      color: #94a3b8;
    }
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">GitHub Pages · 外出先 OK</span>
    <h1>🛡️ まもる計算</h1>
    <p class="sub">家族を守る保障額シミュレーター</p>
    <img src="mamoru_qr_pages.png" alt="まもる計算 公開 QR" class="qr-img" width="240" height="240" />
    <p class="url">${PAGES_URL}</p>
    <div class="steps">
      <strong>スマホで開く手順</strong><br />
      1. カメラで QR を読み取り Safari / Chrome で開く<br />
      2. 共有 →「ホーム画面に追加」<br />
      3. 自宅・外出先どちらからでも利用できます
    </div>
    <p class="hint">※ 初回は GitHub Pages の有効化とデプロイが必要です。404 の場合は docs/GITHUB_PAGES.md を参照。</p>
  </div>
</body>
</html>
EOF

echo ""
echo "=== まもる計算 GitHub Pages QR ==="
echo "公開 URL:   ${PAGES_URL}"
echo "QRページ:   file://${QR_HTML}"
echo "QR画像:     ${QR_PNG}"
echo ""
echo "QRページを開いています..."
open "$QR_HTML" 2>/dev/null || true
