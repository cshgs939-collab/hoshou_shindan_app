#!/bin/bash
# まもる計算 — QRコードでスマホ共有（同一 Wi‑Fi）
set -euo pipefail

export PATH="$HOME/flutter/bin:$PATH"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

PORT="${PORT:-8081}"
HOST="${HOST:-0.0.0.0}"
OUTPUT_DIR="$PROJECT_DIR/outputs"
QR_PNG="$OUTPUT_DIR/mamoru_qr.png"
QR_HTML="$OUTPUT_DIR/mamoru_qr.html"

mkdir -p "$OUTPUT_DIR"

if [ ! -d build/web ] || [ ! -f build/web/index.html ]; then
  echo "Web版をビルドしています..."
  flutter pub get
  flutter build web --release
fi

lan_ip=""
for iface in en0 en1 bridge0; do
  ip=$(ipconfig getifaddr "$iface" 2>/dev/null || true)
  if [ -n "$ip" ]; then
    lan_ip="$ip"
    break
  fi
done

if [ -z "$lan_ip" ]; then
  echo "エラー: LAN IP が取得できません。Wi‑Fi 接続を確認してください。"
  exit 1
fi

APP_URL="http://${lan_ip}:${PORT}"

# サーバー起動（既に動いていればそのまま）
if ! lsof -i ":${PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Webサーバーを起動しています（ポート ${PORT}）..."
  cd build/web
  nohup python3 -m http.server "$PORT" --bind "$HOST" >/tmp/mamoru_web.log 2>&1 &
  cd "$PROJECT_DIR"
  sleep 1
else
  echo "Webサーバーは既にポート ${PORT} で稼働中です。"
fi

echo "QRコードを生成しています..."
curl -fsSL \
  "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${APP_URL}'))")" \
  -o "$QR_PNG"

cat > "$QR_HTML" <<EOF
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>まもる計算 — QRコード</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100dvh;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: "Hiragino Sans", "Yu Gothic", sans-serif;
      background: #f0f7ff;
      color: #0f172a;
      padding: 24px;
    }
    .card {
      background: #fff;
      border: 1px solid #bfdbfe;
      border-radius: 20px;
      padding: 32px 28px;
      text-align: center;
      max-width: 400px;
      width: 100%;
      box-shadow: 0 4px 20px rgba(37, 99, 235, 0.12);
    }
    h1 { margin: 0 0 4px; font-size: 1.35rem; }
    .sub { margin: 0 0 20px; font-size: 0.875rem; color: #64748b; }
    .qr-img {
      width: 240px;
      height: 240px;
      border-radius: 12px;
      border: 1px solid #e2e8f0;
    }
    .url {
      margin-top: 20px;
      font-size: 0.875rem;
      word-break: break-all;
      color: #2563eb;
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
    <h1>🛡️ まもる計算</h1>
    <p class="sub">家族を守る保障額シミュレーター</p>
    <img src="mamoru_qr.png" alt="まもる計算 QRコード" class="qr-img" width="240" height="240" />
    <p class="url">${APP_URL}</p>
    <div class="steps">
      <strong>スマホで開く手順</strong><br />
      1. iPhone / Android を同じ Wi‑Fi に接続<br />
      2. カメラで QR を読み取り Safari / Chrome で開く<br />
      3. 共有 →「ホーム画面に追加」でアプリ風に使えます
    </div>
    <p class="hint">※ 同一 Wi‑Fi 内のみ有効です。外出先から使う場合は GitHub Pages 等への公開が必要です。</p>
  </div>
</body>
</html>
EOF

echo ""
echo "=== まもる計算 QR共有 ==="
echo "Mac ブラウザ:     http://localhost:${PORT}"
echo "スマホ URL:       ${APP_URL}"
echo "QRページ:         file://${QR_HTML}"
echo "QR画像:           ${QR_PNG}"
echo ""
echo "QRページを開いています..."
open "$QR_HTML" 2>/dev/null || true
