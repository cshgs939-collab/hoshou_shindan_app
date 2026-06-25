import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/widget_service.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/diagnosis_input.dart';
import '../../data/models/diagnosis_result.dart';
import '../../data/repositories/hive_repository.dart';
import '../../domain/calculation/calculation_engine.dart';

final calculationEngineProvider = Provider<CalculationEngine>(
  (ref) => CalculationEngine(),
);

final diagnosisResultProvider =
    FutureProvider.family<DiagnosisResult, DiagnosisInput>((ref, input) async {
  final engine = ref.watch(calculationEngineProvider);
  return engine.calculate(input);
});

class HistoryNotifier extends StateNotifier<List<DiagnosisResult>> {
  HistoryNotifier(
    this._repository,
    this._widgetService,
  ) : super(_repository.getHistory());

  final HiveRepository _repository;
  final WidgetService _widgetService;

  Future<DiagnosisResult> saveCurrentDiagnosis(DiagnosisInput input) async {
    final engine = CalculationEngine();
    final savedInput = input.copyWith(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
    );
    final result = engine.calculate(savedInput);
    await _repository.saveDiagnosis(input: savedInput, result: result);
    await _repository.clearDraft();
    state = _repository.getHistory();
    await _widgetService.updateFromResult(result);
    return result;
  }

  Future<void> deleteResult(String id) async {
    await _repository.deleteResult(id);
    state = _repository.getHistory();
    await _widgetService.updateFromResult(state.isEmpty ? null : state.first);
  }

  Future<void> clearAll() async {
    await _repository.clearAllHistory();
    state = [];
    await _widgetService.updateFromResult(null);
  }

  void refresh() {
    state = _repository.getHistory();
  }
}

final diagnosisHistoryProvider =
    StateNotifierProvider<HistoryNotifier, List<DiagnosisResult>>((ref) {
  return HistoryNotifier(
    ref.watch(hiveRepositoryProvider),
    ref.watch(widgetServiceProvider),
  );
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(
    this._repository,
    this._notificationService,
  ) : super(_repository.getSettings());

  final HiveRepository _repository;
  final NotificationService _notificationService;

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    await _repository.saveSettings(state);
  }

  Future<void> setFontSize(int value) async {
    state = state.copyWith(fontSize: value);
    await _repository.saveSettings(state);
  }

  Future<void> setNotificationEnabled(bool value) async {
    state = state.copyWith(notificationEnabled: value);
    await _repository.saveSettings(state);
    await _notificationService.syncFromSettings(state);
  }

  Future<void> setNotificationMonth(int month) async {
    state = state.copyWith(notificationMonth: month);
    await _repository.saveSettings(state);
    if (state.notificationEnabled) {
      await _notificationService.syncFromSettings(state);
    }
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isOnboardingDone: true);
    await _repository.saveSettings(state);
  }

  Future<void> updateLastOpened() async {
    state = state.copyWith(lastOpenedAt: DateTime.now());
    await _repository.saveSettings(state);
  }
}

final appSettingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(
    ref.watch(hiveRepositoryProvider),
    ref.watch(notificationServiceProvider),
  );
});

final latestResultProvider = Provider<DiagnosisResult?>((ref) {
  final history = ref.watch(diagnosisHistoryProvider);
  return history.isEmpty ? null : history.first;
});
