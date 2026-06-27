import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/enums/housing_type.dart';
import 'package:hoshou_shindan_app/core/enums/pension_mode.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/data/export/diagnosis_export.dart';
import 'package:hoshou_shindan_app/data/export/diagnosis_pdf_exporter.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/domain/calculation/calculation_engine.dart';
import 'package:hoshou_shindan_app/domain/calculation/coverage_timeline.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final input = DiagnosisInput(
    id: 'input-1',
    createdAt: DateTime(2026, 6, 10),
    age: 35,
    hasSpouse: true,
    spouseAge: 33,
    childrenAges: const [3],
    schoolType: EducationPolicy.publicAll.index,
    annualIncome: 600,
    spouseIncome: 200,
    monthlyExpense: 25,
    housingType: HousingType.mortgaged.index,
    mortgageBalance: 3000,
    lifeInsurance: 500,
    termInsurance: 500,
    financialAssets: 300,
    pensionMode: SurvivorPensionMode.auto.index,
    workingYears: 20,
  );

  final result = CalculationEngine().calculate(input);

  test('診断JSONに入力と結果が含まれる', () {
    final json = diagnosisRecordToJson(input: input, result: result);
    expect(json['app'], 'まもる計算');
    expect(json['input'], isA<Map<String, dynamic>>());
    expect(json['result'], isA<Map<String, dynamic>>());
    expect(json['result']['gap'], result.gap);
  });

  test('履歴JSONをエンコードできる', () {
    final payload = {
      'records': [diagnosisRecordToJson(input: input, result: result)],
    };
    expect(() => jsonEncode(payload), returnsNormally);
  });

  test('PDFバイト列を生成できる', () async {
    final exporter = DiagnosisPdfExporter();
    final bytes = await exporter.buildPdf(input: input, result: result);
    expect(bytes, isNotEmpty);
    expect(bytes.take(4).toList(), [0x25, 0x50, 0x44, 0x46]); // %PDF
  });

  test('PDFに保障額推移データが含まれる', () async {
    final exporter = DiagnosisPdfExporter();
    final bytes = await exporter.buildPdf(input: input, result: result);
    final points = calcCoverageTimeline(input);
    expect(points, isNotEmpty);
    expect(bytes.length, greaterThan(3000));
  });
}
