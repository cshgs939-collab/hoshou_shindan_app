import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/constants/education_costs.dart';
import 'package:hoshou_shindan_app/core/enums/housing_type.dart';
import 'package:hoshou_shindan_app/core/enums/pension_mode.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/domain/calculation/calculation_engine.dart';

DiagnosisInput _sampleInput({
  bool hasSpouse = true,
  List<int> childrenAges = const [3],
  int annualIncome = 600,
  int monthlyExpense = 25,
  HousingType housingType = HousingType.mortgaged,
  int? mortgageBalance = 3000,
  int? monthlyRent,
}) {
  return DiagnosisInput(
    id: 'test',
    createdAt: DateTime(2026, 6, 25),
    age: 35,
    hasSpouse: hasSpouse,
    spouseAge: 33,
    childrenAges: childrenAges,
    schoolType: EducationPolicy.publicAll.index,
    annualIncome: annualIncome,
    spouseIncome: 200,
    monthlyExpense: monthlyExpense,
    housingType: housingType.index,
    mortgageBalance: mortgageBalance,
    monthlyRent: monthlyRent,
    lifeInsurance: 500,
    termInsurance: 500,
    financialAssets: 300,
    pensionMode: SurvivorPensionMode.auto.index,
    workingYears: 20,
  );
}

void main() {
  group('教育費計算テスト', () {
    test('3歳の子ども・公立コース', () {
      final fee = calcEducationFee(3, EducationPolicy.publicAll);
      expect(fee, greaterThan(500));
    });

    test('0歳の子ども・私立コース', () {
      final fee = calcEducationFee(0, EducationPolicy.privateAll);
      expect(fee, greaterThan(2000));
    });

    test('22歳（卒業済み）', () {
      final fee = calcEducationFee(22, EducationPolicy.publicAll);
      expect(fee, equals(0));
    });
  });

  group('老後生活費', () {
    test('65歳から老後期間を算定する（配偶者33歳）', () {
      final input = _sampleInput();
      expect(calcSurvivorLivingYears(input, 19), 32);
      expect(calcRetirementYears(input), 22);
    });

    test('配偶者が65歳以上なら老後のみ', () {
      final input = _sampleInput().copyWith(spouseAge: 70);
      expect(calcSurvivorLivingYears(input, 19), 0);
      expect(calcRetirementYears(input), 20);
    });

    test('生活費は年金と就労収入を控除した不足分', () {
      final input = _sampleInput(monthlyExpense: 30);
      final result = CalculationEngine().calculate(input);
      expect(result.livingExpense, greaterThanOrEqualTo(0));
      expect(result.survivorWorkIncome, greaterThan(0));
    });

    test('団信加入時は住宅ローン残債を住居費に含めない', () {
      final withCredit = _sampleInput(
        housingType: HousingType.mortgaged,
        mortgageBalance: 3000,
      ).copyWith(hasGroupCreditLifeInsurance: true);
      final withoutCredit = withCredit.copyWith(
        hasGroupCreditLifeInsurance: false,
      );
      expect(CalculationEngine().calculate(withCredit).housingFee, 0);
      expect(
        CalculationEngine().calculate(withoutCredit).housingFee,
        3000,
      );
    });
  });

  group('CalculationEngine', () {
    final engine = CalculationEngine();

    test('必要保障額は費目合計になる', () {
      final result = engine.calculate(_sampleInput());
      expect(
        result.requiredAmount,
        result.livingExpense +
            result.educationFee +
            result.housingFee +
            result.funeralFee,
      );
    });

    test('持家完済は住居費0', () {
      final result = engine.calculate(
        _sampleInput(
          housingType: HousingType.owned,
          mortgageBalance: 3000,
        ),
      );
      expect(result.housingFee, 0);
    });

    test('持家ローンは残債を住居費に反映', () {
      final result = engine.calculate(
        _sampleInput(
          housingType: HousingType.mortgaged,
          mortgageBalance: 3000,
        ).copyWith(hasGroupCreditLifeInsurance: false),
      );
      expect(result.housingFee, 3000);
    });

    test('不足額は必要 − 既存（年金は生活費に反映済み）', () {
      final result = engine.calculate(_sampleInput());
      expect(
        result.gap,
        result.requiredAmount - result.existingCoverage,
      );
    });
  });
}
