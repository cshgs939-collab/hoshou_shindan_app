import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/enums/pension_mode.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/core/utils/employment_labels.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/domain/calculation/old_age_pension_calculator.dart';

DiagnosisInput _baseInput({
  bool hasSpouse = true,
  int insuredWorkTypeRaw = 0,
  int spouseEmploymentType = 0,
  int annualIncome = 500,
  int spouseIncome = 200,
}) {
  return DiagnosisInput(
    id: 'old-age-test',
    createdAt: DateTime(2026, 6, 27),
    age: 35,
    hasSpouse: hasSpouse,
    spouseAge: hasSpouse ? 33 : null,
    childrenAges: const [3],
    schoolType: EducationPolicy.publicAll.index,
    annualIncome: annualIncome,
    spouseIncome: spouseIncome,
    monthlyExpense: 25,
    pensionMode: SurvivorPensionMode.auto.index,
    workingYears: 20,
    insuredWorkTypeRaw: insuredWorkTypeRaw,
    spouseEmploymentType: spouseEmploymentType,
  );
}

void main() {
  test('会社員は老齢基礎と老齢厚生の合計を試算する', () {
    final estimate = estimateInsuredOldAgePension(_baseInput());
    expect(estimate.basicAnnualMan, greaterThan(0));
    expect(estimate.kouseiAnnualMan, greaterThan(0));
    expect(estimate.totalMonthlyMan, greaterThan(estimate.basicMonthlyMan));
    expect(estimate.yearsUntilStart, 30);
  });

  test('自営業は老齢厚生が0', () {
    final estimate = estimateInsuredOldAgePension(
      _baseInput(insuredWorkTypeRaw: SpouseEmploymentType.selfEmployed.index),
    );
    expect(estimate.kouseiAnnualMan, equals(0));
    expect(estimate.hasKousei, isFalse);
  });

  test('配偶者なしでもあなたの老齢年金を試算する', () {
    final estimate = estimateInsuredOldAgePension(_baseInput(hasSpouse: false));
    expect(estimateSpouseOldAgePension(_baseInput(hasSpouse: false)), isNull);
    expect(estimate.totalAnnualMan, greaterThan(0));
  });

  test('配偶者の老齢年金も試算する', () {
    final spouse = estimateSpouseOldAgePension(_baseInput());
    expect(spouse, isNotNull);
    expect(spouse!.basicAnnualMan, greaterThan(0));
  });
}
