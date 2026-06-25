#!/bin/bash
# まもる計算 — Web 版ローカルサーバー
set -euo pipefail

export PATH="$HOME/flutter/bin:$PATH"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

PORT="${PORT:-8081}"

if [ ! -d build/web ] || [ ! -f build/web/index.html ]; then
  echo "Building web release..."
  flutter pub get
  flutter build web --release
fi

echo "まもる計算 Web 版: http://localhost:${PORT}"
echo "停止: Ctrl+C"
cd build/web
exec python3 -m http.server "$PORT"
