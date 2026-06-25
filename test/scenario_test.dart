import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/enums/housing_type.dart';
import 'package:hoshou_shindan_app/core/enums/pension_mode.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/domain/calculation/calculation_engine.dart';
import 'package:hoshou_shindan_app/domain/scenario/scenario_comparison.dart';

void main() {
  final baseInput = DiagnosisInput(
    id: 'scenario-test',
    createdAt: DateTime(2026, 6, 25),
    age: 35,
    hasSpouse: true,
    spouseAge: 33,
    childrenAges: const [3],
    schoolType: EducationPolicy.publicAll.index,
    annualIncome: 600,
    monthlyExpense: 25,
    housingType: HousingType.mortgaged.index,
    mortgageBalance: 3000,
    pensionMode: SurvivorPensionMode.auto.index,
    workingYears: 20,
  );

  test('3つの教育方針シナリオを比較できる', () {
    final service = ScenarioComparisonService(CalculationEngine());
    final scenarios = service.compare(baseInput);

    expect(scenarios.length, 3);
    expect(
      scenarios.map((item) => item.policy).toList(),
      ScenarioComparisonService.comparablePolicies,
    );
  });

  test('私立は公立より教育費が高く不足額も増える', () {
    final service = ScenarioComparisonService(CalculationEngine());
    final scenarios = service.compare(baseInput);

    final public = scenarios.firstWhere(
      (item) => item.policy == EducationPolicy.publicAll,
    );
    final private = scenarios.firstWhere(
      (item) => item.policy == EducationPolicy.privateAll,
    );

    expect(private.result.educationFee, greaterThan(public.result.educationFee));
    expect(private.result.gap, greaterThan(public.result.gap));
  });
}
