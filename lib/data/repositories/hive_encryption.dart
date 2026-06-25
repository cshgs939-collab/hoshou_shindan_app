import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/diagnosis_input.dart';
import '../models/diagnosis_result.dart';

const _encryptionKeyName = 'hive_aes_key_v1';
const _migrationFlagName = 'hive_encrypted_migrated_v1';

class HiveEncryption {
  HiveEncryption([FlutterSecureStorage? storage])
      : _storage = kIsWeb ? null : (storage ?? const FlutterSecureStorage());

  final FlutterSecureStorage? _storage;

  Future<HiveAesCipher> getCipher() async {
    if (kIsWeb) {
      return _getWebCipher();
    }

    final storage = _storage!;
    final existing = await storage.read(key: _encryptionKeyName);
    if (existing != null) {
      return HiveAesCipher(base64Url.decode(existing));
    }

    final key = Hive.generateSecureKey();
    await storage.write(
      key: _encryptionKeyName,
      value: base64UrlEncode(key),
    );
    return HiveAesCipher(key);
  }

  Future<HiveAesCipher> _getWebCipher() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_encryptionKeyName);
    if (existing != null) {
      return HiveAesCipher(base64Url.decode(existing));
    }

    final key = Hive.generateSecureKey();
    await prefs.setString(_encryptionKeyName, base64UrlEncode(key));
    return HiveAesCipher(key);
  }

  Future<bool> isMigrated() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_migrationFlagName) ?? false;
    }
    final flag = await _storage!.read(key: _migrationFlagName);
    return flag == 'true';
  }

  Future<void> markMigrated() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationFlagName, true);
      return;
    }
    await _storage!.write(key: _migrationFlagName, value: 'true');
  }
}

class HiveMigrationData {
  const HiveMigrationData({
    required this.inputEntries,
    required this.resultEntries,
    required this.settings,
  });

  final Map<dynamic, DiagnosisInput> inputEntries;
  final Map<dynamic, DiagnosisResult> resultEntries;
  final AppSettings? settings;
}

Future<HiveMigrationData?> readLegacyBoxes() async {
  if (kIsWeb) return null;

  final hasAnyBox = await Hive.boxExists('diagnosisInputBox') ||
      await Hive.boxExists('diagnosisResultBox') ||
      await Hive.boxExists('appSettingsBox');
  if (!hasAnyBox) return null;

  final inputEntries = <dynamic, DiagnosisInput>{};
  final resultEntries = <dynamic, DiagnosisResult>{};
  AppSettings? settings;

  if (await Hive.boxExists('diagnosisInputBox')) {
    final box = await Hive.openBox<DiagnosisInput>('diagnosisInputBox');
    for (final key in box.keys) {
      final value = box.get(key);
      if (value != null) inputEntries[key] = value;
    }
    await box.close();
    await Hive.deleteBoxFromDisk('diagnosisInputBox');
  }

  if (await Hive.boxExists('diagnosisResultBox')) {
    final box = await Hive.openBox<DiagnosisResult>('diagnosisResultBox');
    for (final key in box.keys) {
      final value = box.get(key);
      if (value != null) resultEntries[key] = value;
    }
    await box.close();
    await Hive.deleteBoxFromDisk('diagnosisResultBox');
  }

  if (await Hive.boxExists('appSettingsBox')) {
    final box = await Hive.openBox<AppSettings>('appSettingsBox');
    settings = box.get('settings');
    await box.close();
    await Hive.deleteBoxFromDisk('appSettingsBox');
  }

  return HiveMigrationData(
    inputEntries: inputEntries,
    resultEntries: resultEntries,
    settings: settings,
  );
}

Future<void> restoreToEncryptedBoxes({
  required HiveAesCipher cipher,
  required HiveMigrationData data,
}) async {
  final inputBox = await Hive.openBox<DiagnosisInput>(
    'diagnosisInputBox',
    encryptionCipher: cipher,
  );
  final resultBox = await Hive.openBox<DiagnosisResult>(
    'diagnosisResultBox',
    encryptionCipher: cipher,
  );
  final settingsBox = await Hive.openBox<AppSettings>(
    'appSettingsBox',
    encryptionCipher: cipher,
  );

  for (final entry in data.inputEntries.entries) {
    await inputBox.put(entry.key, entry.value);
  }
  for (final entry in data.resultEntries.entries) {
    await resultBox.put(entry.key, entry.value);
  }
  if (data.settings != null) {
    await settingsBox.put('settings', data.settings!);
  }

  await inputBox.close();
  await resultBox.close();
  await settingsBox.close();
}

Future<Box<T>> openEncryptedBox<T>(
  String name,
  HiveAesCipher cipher,
) {
  return Hive.openBox<T>(name, encryptionCipher: cipher);
}

int estimateEncryptedPayloadSize(HiveMigrationData data) {
  return max(1, data.inputEntries.length + data.resultEntries.length);
}
