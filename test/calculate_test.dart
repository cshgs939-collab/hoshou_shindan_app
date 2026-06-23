import 'package:flutter_test/flutter_test.dart';

import 'package:hoshou_shindan_app/main.dart';

void main() {
  group('calculate', () {
    test('独身は保障年数0で不足保障額0', () {
      final input = DiagnosisInput()
        ..maritalStatus = MaritalStatus.single
        ..annualIncomeMan = 500;

      final result = calculate(input);

      expect(result.coverageYears, 0);
      expect(result.livingExpenseMan, 0);
      expect(result.shortfallMan, 0);
    });

    test('既婚・子なし・会社員の試算', () {
      final input = DiagnosisInput()
        ..maritalStatus = MaritalStatus.married
        ..childrenCount = 0
        ..annualIncomeMan = 500
        ..employment = EmploymentType.employee;

      final result = calculate(input);

      expect(result.coverageYears, 10);
      expect(result.livingExpenseMan, 2000); // 500 * 0.4 * 10
      expect(result.welfarePensionMan, 1500); // 500 * 0.3 * 10
      expect(result.educationCostMan, 0);
      expect(result.shortfallMan, 500);
    });

    test('不足保障額は常に0以上', () {
      final inputs = [
        DiagnosisInput()..maritalStatus = MaritalStatus.single,
        DiagnosisInput()
          ..maritalStatus = MaritalStatus.married
          ..childrenCount = 2
          ..youngestChildAge = 3
          ..educationType = EducationType.privateSchool,
      ];

      for (final input in inputs) {
        expect(calculate(input).shortfallMan, greaterThanOrEqualTo(0));
      }
    });

    test('buildCompareScenarios は雇用形態の比較を含む', () {
      final input = DiagnosisInput()
        ..maritalStatus = MaritalStatus.married
        ..childrenCount = 1
        ..youngestChildAge = 5
        ..educationType = EducationType.publicSchool;

      final scenarios = buildCompareScenarios(input);

      expect(scenarios.length, greaterThanOrEqualTo(3));
      expect(scenarios.first.isBaseline, isTrue);
    });
  });
}
