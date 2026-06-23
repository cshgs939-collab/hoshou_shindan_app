#!/bin/bash
# 必要保障額診断 — Android 実機/エミュレータ起動スクリプト
set -euo pipefail

export JAVA_HOME="${JAVA_HOME:-$HOME/.local/jdk-17/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$HOME/flutter/bin:$PATH"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

AVD_NAME="${AVD_NAME:-Pixel_7_API_35}"

start_emulator() {
  if adb devices | grep -q 'emulator.*device'; then
    echo "Emulator already running."
    return
  fi
  echo "Starting emulator: $AVD_NAME"
  nohup emulator -avd "$AVD_NAME" -gpu swiftshader_indirect > /tmp/emulator.log 2>&1 &
  echo "Waiting for boot..."
  for _ in $(seq 1 60); do
    if adb wait-for-device 2>/dev/null; then
      boot=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
      if [ "$boot" = "1" ]; then
        echo "Emulator ready."
        return
      fi
    fi
    sleep 3
  done
  echo "Emulator boot timeout. Check /tmp/emulator.log"
  exit 1
}

case "${1:-run}" in
  doctor)
    flutter doctor -v
    ;;
  devices)
    flutter devices
    ;;
  emulator)
    start_emulator
    flutter devices
    ;;
  apk)
    flutter build apk --debug
    echo "APK: build/app/outputs/flutter-apk/app-debug.apk"
    ;;
  install)
    flutter build apk --debug
    adb install -r build/app/outputs/flutter-apk/app-debug.apk
    ;;
  run)
    if ! adb devices | grep -q 'device$'; then
      start_emulator
    fi
    flutter run -d "$(adb devices | awk '/device$/{print $1; exit}')"
    ;;
  *)
    echo "Usage: $0 [doctor|devices|emulator|apk|install|run]"
    exit 1
    ;;
esac
