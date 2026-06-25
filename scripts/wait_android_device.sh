#!/bin/bash
# USB 接続の Android 実機を待って APK をインストール・起動
set -euo pipefail

export JAVA_HOME="${JAVA_HOME:-$HOME/.local/jdk-17/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$HOME/flutter/bin:$PATH"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APK="${APK:-$PROJECT_DIR/releases/まもる計算_v2.0.0.apk}"
TIMEOUT="${TIMEOUT:-120}"

echo "Android 実機を待っています（最大 ${TIMEOUT} 秒）..."
echo "スマホ側: USB デバッグ ON、Mac 接続時に「許可」をタップ"
echo ""

deadline=$((SECONDS + TIMEOUT))
device=""

while [ "$SECONDS" -lt "$deadline" ]; do
  device=$(adb devices | awk '/\tdevice$/{print $1; exit}')
  if [ -n "$device" ] && [[ "$device" != emulator-* ]]; then
    break
  fi
  device=""
  sleep 2
done

if [ -z "$device" ]; then
  echo "実機が見つかりませんでした。"
  echo "  adb devices"
  echo "で接続を確認してください。"
  exit 1
fi

echo "実機を検出: $device"

if [ ! -f "$APK" ]; then
  echo "APK が見つかりません。ビルドします..."
  cd "$PROJECT_DIR"
  flutter build apk --release
  APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
fi

adb -s "$device" install -r "$APK"
adb -s "$device" shell pm grant com.hoshou.shindan android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb -s "$device" shell am start -n com.hoshou.shindan/com.example.hoshou_shindan_app.MainActivity

echo ""
echo "インストール・起動完了。スマホ画面を確認してください。"
echo "ログ: adb -s $device logcat -s flutter"
