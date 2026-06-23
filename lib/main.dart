import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const HoshouShindanApp());
}

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

class AppColors {
  static const navy = Color(0xFF1A3A5C);
  static const blue = Color(0xFF2563EB);
  static const blueLight = Color(0xFF3B82F6);
  static const background = Color(0xFFF0F2F5);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const accent = Color(0xFF0EA5E9);
  static const living = Color(0xFF2563EB);
  static const education = Color(0xFF7C3AED);
  static const publicCoverage = Color(0xFF059669);
  static const shortfall = Color(0xFFDC2626);
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

enum EmploymentType { employee, selfEmployed }

enum MaritalStatus { single, married }

enum EducationType { publicSchool, privateSchool }

class DiagnosisInput {
  int age = 35;
  int annualIncomeMan = 500; // 万円
  EmploymentType employment = EmploymentType.employee;
  MaritalStatus maritalStatus = MaritalStatus.married;
  int childrenCount = 0;
  int youngestChildAge = 0;
  EducationType educationType = EducationType.publicSchool;

  DiagnosisInput copy() {
    return DiagnosisInput()
      ..age = age
      ..annualIncomeMan = annualIncomeMan
      ..employment = employment
      ..maritalStatus = maritalStatus
      ..childrenCount = childrenCount
      ..youngestChildAge = youngestChildAge
      ..educationType = educationType;
  }

  Map<String, dynamic> toJson() => {
        'age': age,
        'annualIncomeMan': annualIncomeMan,
        'employment': employment.index,
        'maritalStatus': maritalStatus.index,
        'childrenCount': childrenCount,
        'youngestChildAge': youngestChildAge,
        'educationType': educationType.index,
      };

  static DiagnosisInput fromJson(Map<String, dynamic> json) {
    return DiagnosisInput()
      ..age = json['age'] as int? ?? 35
      ..annualIncomeMan = json['annualIncomeMan'] as int? ?? 500
      ..employment = EmploymentType.values[json['employment'] as int? ?? 0]
      ..maritalStatus = MaritalStatus.values[json['maritalStatus'] as int? ?? 1]
      ..childrenCount = json['childrenCount'] as int? ?? 0
      ..youngestChildAge = json['youngestChildAge'] as int? ?? 0
      ..educationType =
          EducationType.values[json['educationType'] as int? ?? 0];
  }
}

class DiagnosisResult {
  final int coverageYears;
  final double livingExpenseMan;
  final double educationCostMan;
  final double basicPensionMan;
  final double welfarePensionMan;
  final double publicCoverageMan;
  final double shortfallMan;

  const DiagnosisResult({
    required this.coverageYears,
    required this.livingExpenseMan,
    required this.educationCostMan,
    required this.basicPensionMan,
    required this.welfarePensionMan,
    required this.publicCoverageMan,
    required this.shortfallMan,
  });

  double get totalNeedMan => livingExpenseMan + educationCostMan;

  Map<String, dynamic> toJson() => {
        'coverageYears': coverageYears,
        'livingExpenseMan': livingExpenseMan,
        'educationCostMan': educationCostMan,
        'basicPensionMan': basicPensionMan,
        'welfarePensionMan': welfarePensionMan,
        'publicCoverageMan': publicCoverageMan,
        'shortfallMan': shortfallMan,
      };

  static DiagnosisResult fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      coverageYears: json['coverageYears'] as int? ?? 0,
      livingExpenseMan: (json['livingExpenseMan'] as num?)?.toDouble() ?? 0,
      educationCostMan: (json['educationCostMan'] as num?)?.toDouble() ?? 0,
      basicPensionMan: (json['basicPensionMan'] as num?)?.toDouble() ?? 0,
      welfarePensionMan: (json['welfarePensionMan'] as num?)?.toDouble() ?? 0,
      publicCoverageMan: (json['publicCoverageMan'] as num?)?.toDouble() ?? 0,
      shortfallMan: (json['shortfallMan'] as num?)?.toDouble() ?? 0,
    );
  }
}

DiagnosisResult calculate(DiagnosisInput input) {
  final income = input.annualIncomeMan.toDouble();

  int coverageYears;
  if (input.maritalStatus == MaritalStatus.single) {
    coverageYears = 0;
  } else if (input.childrenCount == 0) {
    coverageYears = 10;
  } else {
    coverageYears = (22 - input.youngestChildAge).clamp(0, 22);
  }

  final livingExpense = income * 0.4 * coverageYears;

  final educationPerChild =
      input.educationType == EducationType.publicSchool ? 800.0 : 1500.0;
  final educationCost = educationPerChild * input.childrenCount;

  double basicPension = 0;
  if (input.childrenCount > 0 && coverageYears > 0) {
    basicPension =
        (80.0 + 23.0 * input.childrenCount) * coverageYears;
  }

  double welfarePension = 0;
  if (input.employment == EmploymentType.employee && coverageYears > 0) {
    welfarePension = income * 0.3 * coverageYears;
  }

  final publicCoverage = basicPension + welfarePension;
  final rawShortfall = livingExpense + educationCost - publicCoverage;
  final shortfall = rawShortfall < 0 ? 0.0 : rawShortfall;

  return DiagnosisResult(
    coverageYears: coverageYears,
    livingExpenseMan: livingExpense,
    educationCostMan: educationCost,
    basicPensionMan: basicPension,
    welfarePensionMan: welfarePension,
    publicCoverageMan: publicCoverage,
    shortfallMan: shortfall,
  );
}

String formatManYen(double value) {
  if (value == 0) return '0万円';
  if (value >= 10000) {
    final oku = value / 10000;
    if (oku == oku.roundToDouble()) {
      return '${oku.toInt()}億円';
    }
    return '${oku.toStringAsFixed(1)}億円';
  }
  if (value == value.roundToDouble()) {
    return '${value.toInt()}万円';
  }
  return '${value.toStringAsFixed(1)}万円';
}

// ---------------------------------------------------------------------------
// Storage & sharing
// ---------------------------------------------------------------------------

class SavedDiagnosis {
  final DiagnosisInput input;
  final DiagnosisResult result;
  final DateTime savedAt;

  const SavedDiagnosis({
    required this.input,
    required this.result,
    required this.savedAt,
  });
}

class DiagnosisStorage {
  static const _keyInput = 'last_diagnosis_input';
  static const _keyResult = 'last_diagnosis_result';
  static const _keySavedAt = 'last_diagnosis_saved_at';

  static Future<void> save(DiagnosisInput input, DiagnosisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInput, jsonEncode(input.toJson()));
    await prefs.setString(_keyResult, jsonEncode(result.toJson()));
    await prefs.setString(_keySavedAt, DateTime.now().toIso8601String());
  }

  static Future<SavedDiagnosis?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final inputJson = prefs.getString(_keyInput);
    final resultJson = prefs.getString(_keyResult);
    final savedAtRaw = prefs.getString(_keySavedAt);
    if (inputJson == null || resultJson == null || savedAtRaw == null) {
      return null;
    }
    return SavedDiagnosis(
      input: DiagnosisInput.fromJson(
        jsonDecode(inputJson) as Map<String, dynamic>,
      ),
      result: DiagnosisResult.fromJson(
        jsonDecode(resultJson) as Map<String, dynamic>,
      ),
      savedAt: DateTime.parse(savedAtRaw),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInput);
    await prefs.remove(_keyResult);
    await prefs.remove(_keySavedAt);
  }
}

String _employmentLabel(EmploymentType type) =>
    type == EmploymentType.employee ? '会社員' : '自営業';

String _maritalLabel(MaritalStatus status) =>
    status == MaritalStatus.single ? '独身' : '既婚';

String _educationLabel(EducationType type) =>
    type == EducationType.publicSchool ? '国公立' : '私立';

String buildDiagnosisShareText(DiagnosisInput input, DiagnosisResult result) {
  final buffer = StringBuffer()
    ..writeln('【必要保障額診断】結果（簡易試算）')
    ..writeln()
    ..writeln('不足保障額：${formatManYen(result.shortfallMan)}')
    ..writeln('生活費保障額：${formatManYen(result.livingExpenseMan)}')
    ..writeln('教育費：${formatManYen(result.educationCostMan)}')
    ..writeln('公的保障見込み：${formatManYen(result.publicCoverageMan)}')
    ..writeln('保障年数：${result.coverageYears}年')
    ..writeln()
    ..writeln('--- 入力内容 ---')
    ..writeln('年齢：${input.age}歳')
    ..writeln('年収：${input.annualIncomeMan}万円')
    ..writeln('雇用形態：${_employmentLabel(input.employment)}')
    ..writeln('婚姻状況：${_maritalLabel(input.maritalStatus)}');
  if (input.maritalStatus == MaritalStatus.married) {
    buffer
      ..writeln('お子さま：${input.childrenCount}人')
      ..writeln('最年少の年齢：${input.youngestChildAge}歳')
      ..writeln('進学タイプ：${_educationLabel(input.educationType)}');
  }
  buffer
    ..writeln()
    ..writeln('※本結果は簡易試算です。実際の年金・必要保障額は個別の状況により異なります。')
    ..writeln('※本アプリは保険商品の提案・勧誘を目的としたものではありません。');
  return buffer.toString();
}

const kDisclaimerText =
    '本アプリの計算結果は、一般的な前提に基づく簡易試算です。'
    '実際の遺族年金額・必要保障額は、加入歴、所得、家族構成、'
    '既存の保険加入状況等により大きく異なります。'
    '本結果をもとに保険契約等の意思決定を行わず、'
    '正確な試算や生活設計については、年金事務所やファイナンシャルプランナー等の'
    '専門家にご相談ください。'
    '本アプリは特定の保険商品の提案・勧誘・販売を目的としたものではありません。'
    'すべての計算は端末内で行われ、入力データが外部サーバーに送信されることはありません。';

List<CompareScenario> buildCompareScenarios(DiagnosisInput base) {
  final scenarios = <CompareScenario>[
    CompareScenario(
      label: '現在の入力',
      subtitle: _scenarioSubtitle(base),
      input: base.copy(),
      isBaseline: true,
    ),
  ];

  if (base.childrenCount > 0) {
    for (final type in EducationType.values) {
      if (type == base.educationType) continue;
      final alt = base.copy()..educationType = type;
      scenarios.add(
        CompareScenario(
          label: _educationLabel(type),
          subtitle: '進学タイプを変更した場合',
          input: alt,
        ),
      );
    }
  }

  final altEmployment = base.copy()
    ..employment = base.employment == EmploymentType.employee
        ? EmploymentType.selfEmployed
        : EmploymentType.employee;
  scenarios.add(
    CompareScenario(
      label: _employmentLabel(altEmployment.employment),
      subtitle: '雇用形態を変更した場合',
      input: altEmployment,
    ),
  );

  return scenarios;
}

String _scenarioSubtitle(DiagnosisInput input) {
  final parts = <String>[
    _employmentLabel(input.employment),
    _maritalLabel(input.maritalStatus),
  ];
  if (input.childrenCount > 0) {
    parts.add('${_educationLabel(input.educationType)}・${input.childrenCount}人');
  }
  return parts.join(' / ');
}

class CompareScenario {
  final String label;
  final String subtitle;
  final DiagnosisInput input;
  final bool isBaseline;

  const CompareScenario({
    required this.label,
    required this.subtitle,
    required this.input,
    this.isBaseline = false,
  });

  DiagnosisResult get result => calculate(input);
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------

class HoshouShindanApp extends StatelessWidget {
  const HoshouShindanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '必要保障額診断',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          primary: AppColors.navy,
          secondary: AppColors.blueLight,
          surface: AppColors.card,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.navy),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Home Screen
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SavedDiagnosis? _saved;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await DiagnosisStorage.load();
    if (mounted) setState(() => _saved = saved);
  }

  String _formatSavedAt(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _HomeHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.analytics_outlined,
                                size: 40,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '必要保障額診断',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '年齢・年収・家族構成などから、\n死亡時に不足する可能性のある\n保障額を簡易試算します。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InfoTile(
                      icon: Icons.timer_outlined,
                      title: '所要時間 約2分',
                      subtitle: '7つの質問に答えるだけ',
                    ),
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.phone_android_outlined,
                      title: '端末内で完結',
                      subtitle: 'データは外部に送信されません',
                    ),
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.info_outline,
                      title: '簡易試算です',
                      subtitle: '実際の保障額は個別の状況により異なります',
                    ),
                    const SizedBox(height: 32),
                    if (_saved != null) ...[
                      Card(
                        color: AppColors.blue.withValues(alpha: 0.06),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.history, color: AppColors.navy, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '前回の診断結果',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '不足保障額：${formatManYen(_saved!.result.shortfallMan)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '保存日時：${_formatSavedAt(_saved!.savedAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ResultScreen(
                                              input: _saved!.input.copy(),
                                              result: _saved!.result,
                                            ),
                                          ),
                                        );
                                        _loadSaved();
                                      },
                                      child: const Text('結果を見る'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: '保存を削除',
                                    onPressed: () async {
                                      await DiagnosisStorage.clear();
                                      _loadSaved();
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StepInputScreen(
                              initialInput: _saved?.input.copy(),
                            ),
                          ),
                        );
                        _loadSaved();
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('診断をはじめる'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '簡易診断ツール',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'あなたの必要保障額を\nチェック',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.navy, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Input Screen
// ---------------------------------------------------------------------------

class StepInputScreen extends StatefulWidget {
  final DiagnosisInput? initialInput;

  const StepInputScreen({super.key, this.initialInput});

  @override
  State<StepInputScreen> createState() => _StepInputScreenState();
}

class _StepInputScreenState extends State<StepInputScreen> {
  late final DiagnosisInput _input;

  @override
  void initState() {
    super.initState();
    _input = widget.initialInput?.copy() ?? DiagnosisInput();
  }

  int _currentStep = 0;

  List<_StepDef> get _steps {
    final steps = <_StepDef>[
      _StepDef(
        title: '年齢',
        subtitle: '現在の年齢を入力してください',
        builder: (_) => _AgeStep(input: _input, onChanged: _refresh),
      ),
      _StepDef(
        title: '年収',
        subtitle: '税込み年収（万円）を入力してください',
        builder: (_) => _IncomeStep(input: _input, onChanged: _refresh),
      ),
      _StepDef(
        title: '雇用形態',
        subtitle: '現在の雇用形態を選択してください',
        builder: (_) => _EmploymentStep(input: _input, onChanged: _refresh),
      ),
      _StepDef(
        title: '婚姻状況',
        subtitle: '現在の婚姻状況を選択してください',
        builder: (_) => _MaritalStep(input: _input, onChanged: _refresh),
      ),
    ];

    if (_input.maritalStatus == MaritalStatus.married) {
      steps.add(
        _StepDef(
          title: 'お子さまの人数',
          subtitle: '扶養しているお子さまの人数',
          builder: (_) => _ChildrenCountStep(input: _input, onChanged: _refresh),
        ),
      );

      if (_input.childrenCount > 0) {
        steps.add(
          _StepDef(
            title: '最年少のお子さまの年齢',
            subtitle: '最も年の若いお子さまの年齢',
            builder: (_) =>
                _YoungestChildAgeStep(input: _input, onChanged: _refresh),
          ),
        );
        steps.add(
          _StepDef(
            title: '進学タイプ',
            subtitle: 'お子さまの進学先の想定',
            builder: (_) =>
                _EducationStep(input: _input, onChanged: _refresh),
          ),
        );
      }
    }

    return steps;
  }

  void _refresh() => setState(() {});

  bool _canProceed() {
    final step = _steps[_currentStep];
    if (step.title == '年齢') {
      return _input.age >= 18 && _input.age <= 80;
    }
    if (step.title == '年収') {
      return _input.annualIncomeMan >= 100 && _input.annualIncomeMan <= 5000;
    }
    if (step.title == '最年少のお子さまの年齢') {
      return _input.youngestChildAge >= 0 && _input.youngestChildAge <= 25;
    }
    return true;
  }

  void _next() async {
    if (!_canProceed()) return;
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      final result = calculate(_input);
      await DiagnosisStorage.save(_input, result);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(input: _input.copy(), result: result),
        ),
      );
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    if (_currentStep >= steps.length) {
      _currentStep = steps.length - 1;
    }

    final step = steps[_currentStep];
    final progress = (_currentStep + 1) / steps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('入力'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STEP ${_currentStep + 1} / ${steps.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: step.builder(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: const Text('戻る'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _canProceed() ? _next : null,
                      child: Text(
                        _currentStep < steps.length - 1 ? '次へ' : '結果を見る',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDef {
  final String title;
  final String subtitle;
  final Widget Function(BuildContext) builder;

  const _StepDef({
    required this.title,
    required this.subtitle,
    required this.builder,
  });
}

// --- Step widgets ---

class _AgeStep extends StatelessWidget {
  final DiagnosisInput input;
  final VoidCallback onChanged;

  const _AgeStep({required this.input, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${input.age}',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const Text('歳', style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
        Slider(
          value: input.age.toDouble(),
          min: 18,
          max: 80,
          divisions: 62,
          label: '${input.age}歳',
          activeColor: AppColors.blue,
          onChanged: (v) {
            input.age = v.round();
            onChanged();
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('18歳', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text('80歳', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _IncomeStep extends StatefulWidget {
  final DiagnosisInput input;
  final VoidCallback onChanged;

  const _IncomeStep({required this.input, required this.onChanged});

  @override
  State<_IncomeStep> createState() => _IncomeStepState();
}

class _IncomeStepState extends State<_IncomeStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.input.annualIncomeMan}');
  }

  @override
  void didUpdateWidget(covariant _IncomeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != '${widget.input.annualIncomeMan}') {
      _controller.text = '${widget.input.annualIncomeMan}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = widget.input;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${input.annualIncomeMan}',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '万円',
              style: TextStyle(fontSize: 20, color: AppColors.textSecondary),
            ),
          ],
        ),
        Slider(
          value: input.annualIncomeMan.toDouble().clamp(100, 2000),
          min: 100,
          max: 2000,
          divisions: 38,
          label: '${input.annualIncomeMan}万円',
          activeColor: AppColors.blue,
          onChanged: (v) {
            input.annualIncomeMan = v.round();
            widget.onChanged();
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('100万円', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text('2,000万円', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '直接入力',
            suffixText: '万円',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.blue, width: 2),
            ),
          ),
          onChanged: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null && parsed >= 100 && parsed <= 5000) {
              input.annualIncomeMan = parsed;
              widget.onChanged();
            }
          },
        ),
      ],
    );
  }
}

class _EmploymentStep extends StatelessWidget {
  final DiagnosisInput input;
  final VoidCallback onChanged;

  const _EmploymentStep({required this.input, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChoiceCard(
          label: '会社員',
          description: '厚生年金加入（遺族厚生年金の対象）',
          icon: Icons.business_center_outlined,
          selected: input.employment == EmploymentType.employee,
          onTap: () {
            input.employment = EmploymentType.employee;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          label: '自営業',
          description: '国民年金のみ（遺族厚生年金なし）',
          icon: Icons.storefront_outlined,
          selected: input.employment == EmploymentType.selfEmployed,
          onTap: () {
            input.employment = EmploymentType.selfEmployed;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _MaritalStep extends StatelessWidget {
  final DiagnosisInput input;
  final VoidCallback onChanged;

  const _MaritalStep({required this.input, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChoiceCard(
          label: '独身',
          description: '配偶者・お子さまの入力は不要',
          icon: Icons.person_outline,
          selected: input.maritalStatus == MaritalStatus.single,
          onTap: () {
            input.maritalStatus = MaritalStatus.single;
            input.childrenCount = 0;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          label: '既婚',
          description: '配偶者・お子さまの情報を入力',
          icon: Icons.family_restroom_outlined,
          selected: input.maritalStatus == MaritalStatus.married,
          onTap: () {
            input.maritalStatus = MaritalStatus.married;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _ChildrenCountStep extends StatelessWidget {
  final DiagnosisInput input;
  final VoidCallback onChanged;

  const _ChildrenCountStep({required this.input, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (i) {
        final count = i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ChoiceCard(
            label: count == 0 ? 'お子さまなし' : '$count人',
            description: count == 0 ? '配偶者のみの世帯' : '扶養$count人',
            icon: count == 0
                ? Icons.people_outline
                : Icons.child_care_outlined,
            selected: input.childrenCount == count,
            onTap: () {
              input.childrenCount = count;
              if (count == 0) {
                input.youngestChildAge = 0;
              }
              onChanged();
            },
          ),
        );
      }),
    );
  }
}

class _YoungestChildAgeStep extends StatelessWidget {
  final DiagnosisInput input;
  final VoidCallback onChanged;

  const _YoungestChildAgeStep({required this.input, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${input.youngestChildAge}',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const Text('歳', style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
        Slider(
          value: input.youngestChildAge.toDouble(),
          min: 0,
          max: 22,
          divisions: 22,
          label: '${input.youngestChildAge}歳',
          activeColor: AppColors.blue,
          onChanged: (v) {
            input.youngestChildAge = v.round();
            onChanged();
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0歳', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text('22歳', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _EducationStep extends StatelessWidget {
  final DiagnosisInput input;
  final VoidCallback onChanged;

  const _EducationStep({required this.input, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChoiceCard(
          label: '国公立',
          description: '教育費目安：800万円／人',
          icon: Icons.school_outlined,
          selected: input.educationType == EducationType.publicSchool,
          onTap: () {
            input.educationType = EducationType.publicSchool;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          label: '私立',
          description: '教育費目安：1,500万円／人',
          icon: Icons.auto_stories_outlined,
          selected: input.educationType == EducationType.privateSchool,
          onTap: () {
            input.educationType = EducationType.privateSchool;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.blue.withValues(alpha: 0.08)
          : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.blue : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.blue : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.navy : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.blue, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compare Screen
// ---------------------------------------------------------------------------

class CompareScreen extends StatelessWidget {
  final DiagnosisInput baseInput;

  const CompareScreen({super.key, required this.baseInput});

  @override
  Widget build(BuildContext context) {
    final scenarios = buildCompareScenarios(baseInput);
    final maxShortfall = scenarios
        .map((s) => s.result.shortfallMan)
        .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('シナリオ比較')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '条件を変えた場合の不足保障額',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '現在の入力と、進学タイプ・雇用形態を変更した場合の試算結果を比較できます。',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...scenarios.map(
              (scenario) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompareScenarioCard(
                  scenario: scenario,
                  maxShortfall: maxShortfall > 0 ? maxShortfall : 1,
                ),
              ),
            ),
            _DisclaimerCard(),
          ],
        ),
      ),
    );
  }
}

class _CompareScenarioCard extends StatelessWidget {
  final CompareScenario scenario;
  final double maxShortfall;

  const _CompareScenarioCard({
    required this.scenario,
    required this.maxShortfall,
  });

  @override
  Widget build(BuildContext context) {
    final result = scenario.result;
    final fraction =
        (result.shortfallMan / maxShortfall).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scenario.isBaseline
                              ? AppColors.navy
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        scenario.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (scenario.isBaseline)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '基準',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formatManYen(result.shortfallMan),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.shortfall,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '不足保障額（試算）',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(color: Colors.grey.shade200),
                    FractionallySizedBox(
                      widthFactor: fraction,
                      child: Container(color: AppColors.shortfall),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _CompareMetricRow(
              label: '生活費保障',
              value: formatManYen(result.livingExpenseMan),
            ),
            _CompareMetricRow(
              label: '教育費',
              value: formatManYen(result.educationCostMan),
            ),
            _CompareMetricRow(
              label: '公的保障',
              value: formatManYen(result.publicCoverageMan),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompareMetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result Screen
// ---------------------------------------------------------------------------

class ResultScreen extends StatelessWidget {
  final DiagnosisInput input;
  final DiagnosisResult result;

  const ResultScreen({
    super.key,
    required this.input,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'ホームに戻る',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ShortfallHeroCard(result: result),
            const SizedBox(height: 20),
            _BreakdownChart(result: result),
            const SizedBox(height: 20),
            _DetailCards(result: result),
            const SizedBox(height: 20),
            _InputSummaryCard(input: input, result: result),
            const SizedBox(height: 20),
            _DisclaimerCard(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Share.share(
                buildDiagnosisShareText(input, result),
                subject: '必要保障額診断 結果（簡易試算）',
              ),
              icon: const Icon(Icons.share_outlined),
              label: const Text('結果を共有'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CompareScreen(baseInput: input),
                  ),
                );
              },
              icon: const Icon(Icons.compare_arrows),
              label: const Text('シナリオ比較'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('ホームに戻る'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => StepInputScreen(initialInput: input.copy()),
                  ),
                );
              },
              child: const Text('もう一度診断する'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ShortfallHeroCard extends StatelessWidget {
  final DiagnosisResult result;

  const _ShortfallHeroCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final hasShortfall = result.shortfallMan > 0;

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.navy,
              AppColors.navy.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '不足保障額（試算）',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              formatManYen(result.shortfallMan),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: hasShortfall ? Colors.white : Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasShortfall
                  ? '公的保障を差し引いた不足見込み額'
                  : '公的保障で必要額をカバーできる見込み',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (result.coverageYears > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '保障年数：${result.coverageYears}年',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreakdownChart extends StatelessWidget {
  final DiagnosisResult result;

  const _BreakdownChart({required this.result});

  @override
  Widget build(BuildContext context) {
    final items = [
      _BarItem(
        label: '生活費保障',
        value: result.livingExpenseMan,
        color: AppColors.living,
      ),
      _BarItem(
        label: '教育費',
        value: result.educationCostMan,
        color: AppColors.education,
      ),
      _BarItem(
        label: '公的保障',
        value: result.publicCoverageMan,
        color: AppColors.publicCoverage,
        isDeduction: true,
      ),
    ];

    final maxValue = [
      result.livingExpenseMan,
      result.educationCostMan,
      result.publicCoverageMan,
      result.totalNeedMan,
    ].reduce((a, b) => a > b ? a : b);

    final chartMax = maxValue > 0 ? maxValue * 1.1 : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.navy, size: 22),
                SizedBox(width: 8),
                Text(
                  '内訳グラフ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '必要保障額と公的保障の内訳',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ...items.map(
              (item) => _HorizontalBar(
                item: item,
                maxValue: chartMax,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _HorizontalBar(
              item: _BarItem(
                label: '不足保障額',
                value: result.shortfallMan,
                color: AppColors.shortfall,
                isTotal: true,
              ),
              maxValue: chartMax,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarItem {
  final String label;
  final double value;
  final Color color;
  final bool isDeduction;
  final bool isTotal;

  const _BarItem({
    required this.label,
    required this.value,
    required this.color,
    this.isDeduction = false,
    this.isTotal = false,
  });
}

class _HorizontalBar extends StatelessWidget {
  final _BarItem item;
  final double maxValue;

  const _HorizontalBar({required this.item, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? (item.value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: item.isTotal ? 15 : 14,
                      fontWeight:
                          item.isTotal ? FontWeight.bold : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.isDeduction) ...[
                    const SizedBox(width: 6),
                    const Text(
                      '（控除）',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                formatManYen(item.value),
                style: TextStyle(
                  fontSize: item.isTotal ? 16 : 14,
                  fontWeight:
                      item.isTotal ? FontWeight.bold : FontWeight.w600,
                  color: item.isTotal ? item.color : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: item.isTotal ? 14 : 12,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(color: Colors.grey.shade200),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCards extends StatelessWidget {
  final DiagnosisResult result;

  const _DetailCards({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AmountTile(
          icon: Icons.home_outlined,
          label: '生活費保障額',
          amount: result.livingExpenseMan,
          color: AppColors.living,
          formula: '年収 × 40% × 保障年数',
        ),
        const SizedBox(height: 12),
        _AmountTile(
          icon: Icons.school_outlined,
          label: '教育費',
          amount: result.educationCostMan,
          color: AppColors.education,
          formula: '進学タイプ × お子さま人数',
        ),
        const SizedBox(height: 12),
        _AmountTile(
          icon: Icons.account_balance_outlined,
          label: '公的保障見込み額',
          amount: result.publicCoverageMan,
          color: AppColors.publicCoverage,
          formula: '遺族基礎年金 + 遺族厚生年金',
          subItems: [
            if (result.basicPensionMan > 0)
              '遺族基礎年金：${formatManYen(result.basicPensionMan)}',
            if (result.welfarePensionMan > 0)
              '遺族厚生年金：${formatManYen(result.welfarePensionMan)}',
          ],
        ),
      ],
    );
  }
}

class _AmountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final String formula;
  final List<String> subItems;

  const _AmountTile({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.formula,
    this.subItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatManYen(amount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formula,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  ...subItems.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputSummaryCard extends StatelessWidget {
  final DiagnosisInput input;
  final DiagnosisResult result;

  const _InputSummaryCard({required this.input, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '入力内容',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _SummaryRow('年齢', '${input.age}歳'),
            _SummaryRow('年収', '${input.annualIncomeMan}万円'),
            _SummaryRow(
              '雇用形態',
              input.employment == EmploymentType.employee ? '会社員' : '自営業',
            ),
            _SummaryRow(
              '婚姻状況',
              input.maritalStatus == MaritalStatus.single ? '独身' : '既婚',
            ),
            if (input.maritalStatus == MaritalStatus.married) ...[
              _SummaryRow('お子さま', '${input.childrenCount}人'),
              if (input.childrenCount > 0) ...[
                _SummaryRow('最年少の年齢', '${input.youngestChildAge}歳'),
                _SummaryRow(
                  '進学タイプ',
                  input.educationType == EducationType.publicSchool
                      ? '国公立'
                      : '私立',
                ),
              ],
            ],
            _SummaryRow('保障年数', '${result.coverageYears}年'),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.amber.shade800, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ご注意（簡易試算について）',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    kDisclaimerText,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
