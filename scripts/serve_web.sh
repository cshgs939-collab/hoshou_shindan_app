#!/bin/bash
# まもる計算 — Web 版ローカルサーバー（iPhone Safari 対応）
set -euo pipefail

export PATH="$HOME/flutter/bin:$PATH"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

PORT="${PORT:-8081}"
HOST="${HOST:-0.0.0.0}"

if [ ! -d build/web ] || [ ! -f build/web/index.html ]; then
  echo "Building web release..."
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

echo ""
echo "=== まもる計算 Web版 ==="
echo "Mac ブラウザ:  http://localhost:${PORT}"
if [ -n "$lan_ip" ]; then
  echo "iPhone Safari: http://${lan_ip}:${PORT}"
  echo ""
  echo "iPhone で開く手順:"
  echo "  1. iPhone を同じ Wi‑Fi に接続"
  echo "  2. Safari で上記 URL を開く"
  echo "  3. 共有 → 「ホーム画面に追加」でアプリ風に使えます"
else
  echo "iPhone: Mac の IP アドレスを確認して http://<IP>:${PORT} を開いてください"
fi
echo ""
echo "停止: Ctrl+C"
echo ""

cd build/web
exec python3 -m http.server "$PORT" --bind "$HOST"
