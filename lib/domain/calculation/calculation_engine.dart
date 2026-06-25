import 'dart:math';

import '../../core/constants/education_costs.dart';
import '../../core/constants/pension_constants.dart';
import '../../core/enums/housing_type.dart';
import '../../core/enums/pension_mode.dart';
import '../../core/utils/employment_advice.dart';
import '../../data/models/diagnosis_input.dart';
import '../../data/models/diagnosis_result.dart';
import 'survivor_pension_calculator.dart';

const int funeralAndEmergencyFee = 300;
const int childIndependenceAge = 22;
const int femaleLifeExpectancy = 87;
const int maleLifeExpectancy = 81;

class CalculationEngine {
  DiagnosisResult calculate(DiagnosisInput input) {
    final livingExpense = calcLivingExpense(input);
    final educationFee = calcTotalEducationFee(input);
    final housingFee = calcHousingFee(input);
    final requiredTotal =
        livingExpense + educationFee + housingFee + funeralAndEmergencyFee;

    final existingCoverage = calcExistingCoverage(input);
    final survivorPension = input.survivorPensionMode == SurvivorPensionMode.auto
        ? calcTotalSurvivorPensionLifetime(input)
        : calcManualSurvivorPension(input);
    final survivorWorkIncome = calcTotalSurvivorWorkIncome(input);
    final gap = requiredTotal - existingCoverage;

    return DiagnosisResult(
      id: '${input.id}_result',
      inputId: input.id,
      calculatedAt: DateTime.now(),
      requiredAmount: requiredTotal,
      existingCoverage: existingCoverage,
      survivorPension: survivorPension,
      survivorWorkIncome: survivorWorkIncome,
      gap: gap,
      livingExpense: livingExpense,
      educationFee: educationFee,
      housingFee: housingFee,
      funeralFee: funeralAndEmergencyFee,
      childrenCount: input.childrenAges.length,
      hasSpouse: input.hasSpouse,
    );
  }
}

/// 生活費不足分＝（必要月額−遺族年金−配偶者就労）× 年数（就労は65歳まで）
int calcLivingExpense(DiagnosisInput input) {
  if (!input.hasSpouse && input.childrenAges.isEmpty) {
    return 0;
  }

  return calcPreRetirementLivingExpense(input) +
      calcRetirementLivingExpense(input);
}

int calcPreRetirementLivingExpense(DiagnosisInput input) {
  final spouseAge = input.spouseAge ?? input.age;
  if (spouseAge >= retirementStartAge) return 0;

  final yearsTo65 = retirementStartAge - spouseAge;
  if (yearsTo65 <= 0) return 0;

  final monthlyNeed =
      (_monthlyLivingExpenseBase(input) * _livingExpenseCoefficient(input))
          .round();
  final workMonthly = estimateSurvivorWorkMonthly(input);
  final childYears = min(calcYearsUntilChild18End(input), yearsTo65);
  final afterChildYears = yearsTo65 - childYears;

  var total = 0;
  if (childYears > 0) {
    final pensionMonthly = _monthlyPensionForPhase(
      input,
      SurvivorPensionPhaseKind.withChild,
    );
    total += _phaseShortfall(
      monthlyNeed: monthlyNeed,
      pensionMonthly: pensionMonthly,
      workMonthly: workMonthly,
      years: childYears,
    );
  }
  if (afterChildYears > 0) {
    final pensionMonthly = _monthlyPensionForPhase(
      input,
      SurvivorPensionPhaseKind.afterChildBefore65,
    );
    total += _phaseShortfall(
      monthlyNeed: monthlyNeed,
      pensionMonthly: pensionMonthly,
      workMonthly: workMonthly,
      years: afterChildYears,
    );
  }
  return total;
}

int calcRetirementLivingExpense(DiagnosisInput input) {
  final years = calcRetirementYears(input);
  if (years <= 0) return 0;

  final monthlyNeed = input.retirementMonthlyExpense;
  final pensionMonthly = _monthlyPensionForPhase(
    input,
    SurvivorPensionPhaseKind.after65,
  );
  return _phaseShortfall(
    monthlyNeed: monthlyNeed,
    pensionMonthly: pensionMonthly,
    workMonthly: 0,
    years: years,
  );
}

int _phaseShortfall({
  required int monthlyNeed,
  required int pensionMonthly,
  required int workMonthly,
  required int years,
}) {
  return max(0, monthlyNeed - pensionMonthly - workMonthly) * 12 * years;
}

int _monthlyPensionForPhase(
  DiagnosisInput input,
  SurvivorPensionPhaseKind kind,
) {
  final annual = calcSurvivorPensionAnnualForPhase(input, kind);
  return max(0, (annual / 12).round());
}

int _monthlyLivingExpenseBase(DiagnosisInput input) {
  if (input.residenceType == HousingType.renting &&
      input.monthlyRent != null &&
      input.monthlyRent! > 0) {
    return max(0, input.monthlyExpense - input.monthlyRent!);
  }
  return input.monthlyExpense;
}

double _livingExpenseCoefficient(DiagnosisInput input) {
  final hasChildren = input.childrenAges.isNotEmpty;
  if (input.hasSpouse && hasChildren) return 0.70;
  if (input.hasSpouse && !hasChildren) return 0.50;
  if (!input.hasSpouse && hasChildren) return 0.60;
  return 0.50;
}

int calcYearsUntilYoungestIndependent(DiagnosisInput input) {
  if (input.childrenAges.isEmpty) return 0;
  return max(0, childIndependenceAge - input.youngestChildAge);
}

int calcSurvivorLivingYears(
  DiagnosisInput input,
  int yearsUntilYoungestIndependent,
) {
  if (!input.hasSpouse || input.spouseAge == null) {
    return yearsUntilYoungestIndependent;
  }
  final spouseAge = input.spouseAge!;
  if (spouseAge >= retirementStartAge) return 0;
  return retirementStartAge - spouseAge;
}

int calcRetirementYears(DiagnosisInput input) {
  if (!input.hasSpouse || input.spouseAge == null) return 0;

  final lifeEndAge = _estimateSpouseLifeExpectancy(input.spouseAge!);
  if (lifeEndAge <= retirementStartAge) return 0;

  if (input.spouseAge! >= retirementStartAge) {
    return lifeEndAge - input.spouseAge!;
  }
  return lifeEndAge - retirementStartAge;
}

int _estimateSpouseLifeExpectancy(int spouseAge) {
  final remaining = spouseAge < 65 ? femaleLifeExpectancy - spouseAge : 20;
  return spouseAge + remaining;
}

int calcTotalEducationFee(DiagnosisInput input) {
  if (input.childrenAges.isEmpty) return 0;
  var total = 0;
  for (var i = 0; i < input.childrenAges.length; i++) {
    total += calcEducationFee(
      input.childrenAges[i],
      input.educationPolicyForChild(i),
    );
  }
  return total;
}

int calcHousingFee(DiagnosisInput input) {
  switch (input.residenceType) {
    case HousingType.mortgaged:
      if (input.hasGroupCreditLifeInsurance) return 0;
      return input.mortgageBalance ?? 0;
    case HousingType.renting:
      final totalYears = calcRemainingLivingYears(input);
      return (input.monthlyRent ?? 0) * 12 * totalYears;
    case HousingType.owned:
      return 0;
  }
}

int calcRemainingLivingYears(DiagnosisInput input) {
  final childYears = calcYearsUntilYoungestIndependent(input);
  final survivorYears = calcSurvivorLivingYears(input, childYears);
  final retirementYears = calcRetirementYears(input);
  return survivorYears + retirementYears;
}

int calcExistingCoverage(DiagnosisInput input) {
  final incomeProtectionTotal = input.incomeProtectionMonthly *
      12 *
      input.incomeProtectionYears;
  return input.lifeInsurance +
      input.termInsurance +
      incomeProtectionTotal +
      input.retirementPay +
      input.financialAssets;
}

int calcManualSurvivorPension(DiagnosisInput input) {
  final annual = input.manualPensionAnnual ?? 0;
  final years = calcRemainingLivingYears(input);
  return annual * max(years, 1);
}

// 後方互換（テスト・旧呼び出し）
int calcMonthlySurvivorPension(
  DiagnosisInput input, {
  bool withChildAddition = false,
}) {
  final kind = withChildAddition
      ? SurvivorPensionPhaseKind.withChild
      : SurvivorPensionPhaseKind.afterChildBefore65;
  return _monthlyPensionForPhase(input, kind);
}

String buildAdviceText(DiagnosisInput input, DiagnosisResult result) {
  final parts = <String>[];
  final coverage = describeInsuredIncomeCoverage(input);

  if (coverage != null && coverage.uncoveredMonthlyMan > 0) {
    parts.add(
      'あなたの年収（月${coverage.monthlyIncomeMan}万円相当）のうち、'
      '公的年金（遺族年金）の概算は月${coverage.monthlyPensionMan}万円です。'
      '約${coverage.uncoveredMonthlyMan}万円/月は公的年金では補えません。',
    );
    parts.add(
      'この収入不足分に加え、生活費・教育費・住居費なども'
      '生命保険等で備える必要があります。',
    );
  }

  if (result.gap > 0) {
    parts.add('試算では、既存の保障を差し引いた不足額は約${result.gap}万円です。');
    final monthlyPremium = (result.gap * 0.0022).round();
    parts.add(
      '定期保険（掛捨型）で全額を確保すると、'
      '月々約${_formatPremium(monthlyPremium)}円〜が目安です。',
    );
  } else if (result.gap < 0) {
    parts.add(
      '現在の保障は必要額を上回っています。'
      '保険料の見直しで家計の余力を増やせる可能性があります。',
    );
  } else if (parts.isEmpty) {
    parts.add(
      '必要保障額と既存保障が概ね一致しています。'
      'ライフステージの変化に合わせて定期的な見直しをおすすめします。',
    );
  }

  return parts.join(' ');
}

String _formatPremium(int yen) {
  if (yen >= 10000) {
    final man = yen ~/ 10000;
    final rest = yen % 10000;
    if (rest == 0) return '$man万';
    return '$man万${rest.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
  return yen.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
