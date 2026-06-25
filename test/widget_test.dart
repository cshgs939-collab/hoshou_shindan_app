import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/data/models/app_settings.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_result.dart';
import 'package:hoshou_shindan_app/data/repositories/hive_repository.dart';
import 'package:hoshou_shindan_app/presentation/screens/home/home_screen.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HiveRepository repository;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive');
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DiagnosisInputAdapter());
      Hive.registerAdapter(DiagnosisResultAdapter());
      Hive.registerAdapter(AppSettingsAdapter());
    }
    final inputBox = await Hive.openBox<DiagnosisInput>('test_input_widget');
    final resultBox = await Hive.openBox<DiagnosisResult>('test_result_widget');
    final settingsBox =
        await Hive.openBox<AppSettings>('test_settings_widget');
    repository = HiveRepository(
      inputBox: inputBox,
      resultBox: resultBox,
      settingsBox: settingsBox,
    );
    await settingsBox.put('settings', AppSettings(isOnboardingDone: true));
  });

  testWidgets('ホーム画面が表示される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hiveRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('まもる計算'), findsOneWidget);
    expect(find.text('入力する数字'), findsOneWidget);
    expect(find.text('操作手順'), findsOneWidget);
  });
}
