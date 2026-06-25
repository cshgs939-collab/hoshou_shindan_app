#!/bin/bash
# エミュレータ上でストア用スクリーンショットを自動取得
set -euo pipefail

export JAVA_HOME="${JAVA_HOME:-$HOME/.local/jdk-17/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$PROJECT_DIR/docs/store"
PKG="com.hoshou.shindan"
ACTIVITY="com.hoshou.shindan/com.example.hoshou_shindan_app.MainActivity"
APK="${APK:-$PROJECT_DIR/releases/まもる計算_v2.0.0.apk}"

mkdir -p "$OUT_DIR"

device=$(adb devices | awk '/\tdevice$/{print $1; exit}')
if [ -z "$device" ]; then
  echo "エミュレータまたは実機を接続してください。"
  exit 1
fi
echo "デバイス: $device"

shot() {
  local name="$1"
  sleep 1
  adb exec-out screencap -p > "$OUT_DIR/$name"
  echo "  saved: docs/store/$name"
}

tap_text() {
  local text="$1"
  adb shell uiautomator dump /sdcard/window_dump.xml >/dev/null 2>&1
  adb pull /sdcard/window_dump.xml /tmp/window_dump.xml >/dev/null 2>&1
  python3 - "$text" <<'PY'
import re, sys, xml.etree.ElementTree as ET
target = sys.argv[1]
root = ET.parse('/tmp/window_dump.xml').getroot()
for node in root.iter('node'):
    t = node.get('text') or ''
    d = node.get('content-desc') or ''
    if target in t or target in d:
        b = node.get('bounds')
        m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', b or '')
        if m:
            x1, y1, x2, y2 = map(int, m.groups())
            print((x1 + x2) // 2, (y1 + y2) // 2)
            sys.exit(0)
sys.exit(1)
PY
}

scroll_down() {
  adb shell input swipe 540 1800 540 600 350
  sleep 0.5
}

tap_primary() {
  scroll_down
  try_tap_text "計算する" && return 0
  try_tap_text "次へ" && return 0
  tap 540 2200
}

try_tap_text() {
  local text="$1"
  if coords=$(tap_text "$text" 2>/dev/null); then
    set -- $coords
    tap "$1" "$2"
    return 0
  fi
  return 1
}

tap() {
  local x="$1" y="$2"
  adb shell input tap "$x" "$y"
}

echo "=== まもる計算 スクリーンショット取得 ==="

if [ -f "$APK" ]; then
  adb install -r "$APK" >/dev/null
fi
adb shell pm clear "$PKG" >/dev/null
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb shell am start -n "$ACTIVITY" >/dev/null
sleep 4

echo "[1/5] オンボーディング"
shot "01_onboarding.png"
try_tap_text "スキップ" || tap 980 120
sleep 2

echo "[2/5] ホーム"
shot "02_home.png"
try_tap_text "診断スタート" || tap 540 900
sleep 2

echo "[3/5] ステップ1"
scroll_down
shot "03_step1.png"
tap_primary
sleep 2

echo "[4/5] ステップ2"
scroll_down
shot "04_step2.png"
tap_primary
sleep 2

echo "[5/5] ステップ3 → 結果"
scroll_down
shot "05_step3.png"
tap_primary
sleep 6
shot "06_result.png"

echo "[6/6] シナリオ比較"
try_tap_text "教育方針" || try_tap_text "シナリオ" || true
sleep 2
if adb shell dumpsys activity activities | grep -q scenario; then
  shot "07_scenario.png"
fi

echo ""
echo "完了: $OUT_DIR"
ls -lh "$OUT_DIR"
