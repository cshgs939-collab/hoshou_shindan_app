# Android リリース署名（Play Store 用）

現在の `flutter build apk --release` は **debug キー**で署名しています。Play Store 公開前に release keystore を作成してください。

---

## Step 1: keystore を作成

```bash
mkdir -p ~/.android/keystores
keytool -genkey -v \
  -keystore ~/.android/keystores/mamoru-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mamoru
```

> **重要:** パスワードと keystore ファイルは安全な場所に保管してください。紛失するとアップデート不可になります。

---

## Step 2: key.properties を作成（git に含めない）

`android/key.properties`（`.gitignore` 済み）:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=mamoru
storeFile=/Users/maya2018/.android/keystores/mamoru-release.jks
```

テンプレート:

```bash
cp android/key.properties.example android/key.properties
# 編集してパスワードを設定
```

---

## Step 3: build.gradle.kts に署名設定を追加

`android/app/build.gradle.kts` の `android { }` ブロック内:

```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        // proguardFiles は既存設定を維持
    }
}
```

---

## Step 4: App Bundle をビルド（Play Store 推奨）

```bash
export JAVA_HOME="$HOME/.local/jdk-17/Contents/Home"
flutter build appbundle --release
```

成果物: `build/app/outputs/bundle/release/app-release.aab`

---

## Step 5: ローカル検証

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## チェックリスト

- [ ] release keystore 作成
- [ ] `key.properties` 設定（git 未コミット）
- [ ] `build.gradle.kts` に release signing
- [ ] `flutter build appbundle --release` 成功
- [ ] 実機で署名済み APK 起動確認
