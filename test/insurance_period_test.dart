import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/enums/pension_mode.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/domain/calculation/insurance_period.dart';

void main() {
  test('年齢から保障必要年数と定期保険残り年数を算出', () {
    final input = DiagnosisInput(
      id: 't',
      createdAt: DateTime(2026, 6, 25),
      age: 35,
      hasSpouse: true,
      spouseAge: 33,
      childrenAges: const [3],
      schoolType: EducationPolicy.publicAll.index,
      termInsurance: 2000,
      termInsuranceEndAge: 60,
      pensionMode: SurvivorPensionMode.auto.index,
    );

    final summary = InsurancePeriodSummary.from(input);

    expect(summary.yearsUntilChild18, 15);
    expect(summary.yearsUntilSpouse65, 32);
    expect(summary.recommendedYears, 32);
    expect(calcTermInsuranceRemainingYears(input), 25);
    expect(summary.termCoversRecommended, isFalse);
    expect(summary.termShortfallYears, 7);
  });
}
