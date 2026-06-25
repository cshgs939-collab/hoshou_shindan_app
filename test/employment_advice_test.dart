import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/enums/pension_mode.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/core/utils/employment_advice.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';

DiagnosisInput _input({int insuredWorkTypeRaw = 0}) {
  return DiagnosisInput(
    id: 'advice-test',
    createdAt: DateTime(2026, 6, 25),
    age: 35,
    hasSpouse: true,
    spouseAge: 33,
    childrenAges: const [3],
    schoolType: EducationPolicy.publicAll.index,
    annualIncome: 500,
    spouseIncome: 200,
    monthlyExpense: 20,
    pensionMode: SurvivorPensionMode.auto.index,
    workingYears: 20,
    insuredWorkTypeRaw: insuredWorkTypeRaw,
  );
}

void main() {
  test('年収に対し公的年金で補えない月額を算出する', () {
    final coverage = describeInsuredIncomeCoverage(_input());
    expect(coverage, isNotNull);
    expect(coverage!.monthlyIncomeMan, greaterThan(0));
    expect(coverage.monthlyPensionMan, greaterThan(0));
    expect(coverage.uncoveredMonthlyMan, greaterThan(0));
    expect(
      coverage.incomeGapExplanation(),
      contains('公的年金では補えません'),
    );
  });

  test('自営業は遺族厚生なしで補えない額が大きい', () {
    final company = describeInsuredIncomeCoverage(_input());
    final selfEmployed = describeInsuredIncomeCoverage(
      _input(insuredWorkTypeRaw: SpouseEmploymentType.selfEmployed.index),
    );
    expect(company!.monthlyPensionMan, greaterThan(selfEmployed!.monthlyPensionMan));
    expect(
      selfEmployed.uncoveredMonthlyMan,
      greaterThan(company.uncoveredMonthlyMan),
    );
  });
}
