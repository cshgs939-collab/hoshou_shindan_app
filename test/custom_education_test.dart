import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/domain/calculation/calculation_engine.dart';

void main() {
  test('子どもごとの個別教育方針で教育費が計算される', () {
    final input = DiagnosisInput(
      id: 'custom-child-policy',
      createdAt: DateTime(2026, 6, 25),
      age: 35,
      hasSpouse: true,
      childrenAges: const [3, 8],
      schoolType: EducationPolicy.custom.index,
      childrenSchoolTypes: [
        EducationPolicy.publicAll.index,
        EducationPolicy.privateAll.index,
      ],
      monthlyExpense: 25,
      annualIncome: 600,
    );

    final result = CalculationEngine().calculate(input);

    final olderPublicOnly = DiagnosisInput(
      id: 'single-child',
      createdAt: DateTime(2026, 6, 25),
      age: 35,
      hasSpouse: true,
      childrenAges: const [8],
      schoolType: EducationPolicy.publicAll.index,
      monthlyExpense: 25,
      annualIncome: 600,
    );
    final olderPrivateOnly = olderPublicOnly.copyWith(
      schoolType: EducationPolicy.privateAll.index,
    );

    final publicFee = CalculationEngine().calculate(olderPublicOnly).educationFee;
    final privateFee =
        CalculationEngine().calculate(olderPrivateOnly).educationFee;

    expect(result.educationFee, greaterThan(publicFee));
    expect(result.educationFee, greaterThan(privateFee));
  });
}
