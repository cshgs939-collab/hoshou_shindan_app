import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/diagnosis_input.dart';
import '../models/diagnosis_result.dart';
import 'hive_encryption.dart';

const maxHistoryCount = 20;

class HiveRepository {
  HiveRepository({
    required Box<DiagnosisInput> inputBox,
    required Box<DiagnosisResult> resultBox,
    required Box<AppSettings> settingsBox,
  })  : _inputBox = inputBox,
        _resultBox = resultBox,
        _settingsBox = settingsBox;

  final Box<DiagnosisInput> _inputBox;
  final Box<DiagnosisResult> _resultBox;
  final Box<AppSettings> _settingsBox;

  static const draftKey = 'draft';

  AppSettings getSettings() {
    return _settingsBox.get('settings') ?? AppSettings.defaults();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('settings', settings);
  }

  DiagnosisInput? getDraft() => _inputBox.get(draftKey);

  Future<void> saveDraft(DiagnosisInput input) async {
    await _inputBox.put(draftKey, input);
  }

  Future<void> clearDraft() async {
    await _inputBox.delete(draftKey);
  }

  List<DiagnosisResult> getHistory() {
    final results = _resultBox.values.toList()
      ..sort((a, b) => b.calculatedAt.compareTo(a.calculatedAt));
    return results;
  }

  DiagnosisResult? getResult(String id) => _resultBox.get(id);

  DiagnosisInput? getInput(String id) => _inputBox.get(id);

  Future<void> saveDiagnosis({
    required DiagnosisInput input,
    required DiagnosisResult result,
  }) async {
    await _inputBox.put(input.id, input);
    await _resultBox.put(result.id, result);
    await trimHistory();
  }

  Future<void> deleteResult(String resultId) async {
    final result = _resultBox.get(resultId);
    if (result == null) return;
    await _resultBox.delete(resultId);
    await _inputBox.delete(result.inputId);
  }

  Future<void> clearAllHistory() async {
    final keys = _resultBox.keys.toList();
    for (final key in keys) {
      final result = _resultBox.get(key);
      if (result != null) {
        await _inputBox.delete(result.inputId);
      }
      await _resultBox.delete(key);
    }
  }

  Future<void> trimHistory() async {
    final history = getHistory();
    if (history.length <= maxHistoryCount) return;
    for (final old in history.skip(maxHistoryCount)) {
      await deleteResult(old.id);
    }
  }
}

final hiveRepositoryProvider = Provider<HiveRepository>((ref) {
  throw UnimplementedError('HiveRepository must be overridden in main.dart');
});

Future<HiveRepository> initHiveRepository() async {
  await Hive.initFlutter();
  Hive.registerAdapter(DiagnosisInputAdapter());
  Hive.registerAdapter(DiagnosisResultAdapter());
  Hive.registerAdapter(AppSettingsAdapter());

  final encryption = HiveEncryption();
  final cipher = await encryption.getCipher();
  final migrated = await encryption.isMigrated();

  if (!migrated) {
    final legacy = await readLegacyBoxes();
    if (legacy != null &&
        (legacy.inputEntries.isNotEmpty ||
            legacy.resultEntries.isNotEmpty ||
            legacy.settings != null)) {
      await restoreToEncryptedBoxes(cipher: cipher, data: legacy);
    }
    await encryption.markMigrated();
  }

  final inputBox = await openEncryptedBox<DiagnosisInput>(
    'diagnosisInputBox',
    cipher,
  );
  final resultBox = await openEncryptedBox<DiagnosisResult>(
    'diagnosisResultBox',
    cipher,
  );
  final settingsBox = await openEncryptedBox<AppSettings>(
    'appSettingsBox',
    cipher,
  );

  return HiveRepository(
    inputBox: inputBox,
    resultBox: resultBox,
    settingsBox: settingsBox,
  );
}
