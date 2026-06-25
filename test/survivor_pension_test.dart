import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/enums/insured_employment_type.dart';
import 'package:hoshou_shindan_app/core/enums/pension_mode.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/domain/calculation/calculation_engine.dart';
import 'package:hoshou_shindan_app/domain/calculation/survivor_pension_calculator.dart';

DiagnosisInput _baseInput() {
  return DiagnosisInput(
    id: 'pension-test',
    createdAt: DateTime(2026, 6, 25),
    age: 35,
    hasSpouse: true,
    spouseAge: 33,
    childrenAges: const [3],
    schoolType: EducationPolicy.publicAll.index,
    annualIncome: 500,
    spouseIncome: 200,
    monthlyExpense: 30,
    pensionMode: SurvivorPensionMode.auto.index,
    workingYears: 20,
  );
}

void main() {
  test('自営業は遺族厚生年金0・会社員より総額が少ない', () {
    final company = _baseInput();
    final selfEmployed = company.copyWith(
      insuredWorkTypeRaw: SpouseEmploymentType.selfEmployed.index,
      insuredEmploymentType: InsuredEmploymentType.selfEmployed.index,
    );

    expect(calcSurvivorKouseiAnnual(selfEmployed), 0);
    expect(
      calcTotalSurvivorPensionLifetime(selfEmployed),
      lessThan(calcTotalSurvivorPensionLifetime(company)),
    );
  });

  test('配偶者就労収入が記録される', () {
    final input = _baseInput();
    final result = CalculationEngine().calculate(input);
    expect(result.survivorWorkIncome, greaterThan(0));
  });

  test('子18歳年度末以降は遺族基礎年金フェーズが終了する', () {
    final input = _baseInput();
    final phases = calcSurvivorPensionPhases(input);
    final childPhase = phases.firstWhere(
      (p) => p.kind == SurvivorPensionPhaseKind.withChild,
    );
    expect(childPhase.years, 15);
  });

  test('65歳以降の年金に老齢基礎年金が含まれる', () {
    final input = _baseInput();
    final after65 = calcAfter65PensionAnnual(input);
    expect(after65, greaterThanOrEqualTo(estimateOldAgeBasicAnnual(input)));
    expect(estimateOldAgeBasicAnnual(input), greaterThan(0));
  });

  test('65歳以降は就労を差し引かず公的年金のみ控除', () {
    final input = _baseInput().copyWith(retirementMonthlyExpense: 20);
    final result = CalculationEngine().calculate(input);
    expect(calcRetirementLivingExpense(input), greaterThan(0));
    expect(result.livingExpense, calcPreRetirementLivingExpense(input) +
        calcRetirementLivingExpense(input));
  });
}
