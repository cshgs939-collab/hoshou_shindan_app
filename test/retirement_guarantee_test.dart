import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/enums/housing_type.dart';
import 'package:hoshou_shindan_app/core/enums/pension_mode.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/domain/calculation/calculation_engine.dart';
import 'package:hoshou_shindan_app/domain/calculation/retirement_guarantee_summary.dart';

void main() {
  test('65歳以降の保障残額サマリー（例題）', () {
    final input = DiagnosisInput(
      id: 't',
      createdAt: DateTime(2026, 6, 25),
      age: 35,
      hasSpouse: true,
      spouseAge: 33,
      childrenAges: const [3],
      schoolType: EducationPolicy.publicAll.index,
      annualIncome: 500,
      spouseIncome: 200,
      monthlyExpense: 20,
      housingType: HousingType.renting.index,
      monthlyRent: 10,
      retirementMonthlyExpense: 20,
      spouseEmploymentType: SpouseEmploymentType.partTime.index,
      pensionMode: SurvivorPensionMode.auto.index,
      workingYears: 20,
    );
    final result = CalculationEngine().calculate(input);
    final summary = RetirementGuaranteeSummary.from(
      input: input,
      result: result,
    );

    expect(summary.needMonthlyMan, 20);
    expect(summary.pensionMonthlyMan, closeTo(11, 0.5));
    expect(summary.monthlyShortfallMan, closeTo(9, 0.5));
    expect(summary.monthlyShortfallYen, 90000);
    expect(summary.livingShortfallTotalMan, greaterThan(2000));
    expect(summary.guaranteeNeededMan, result.gap);
  });
}
