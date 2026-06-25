import 'dart:math';

import '../../core/constants/education_costs.dart';
import '../../core/enums/housing_type.dart';
import '../../core/enums/pension_mode.dart';
import '../../data/models/diagnosis_input.dart';
import '../../data/models/diagnosis_result.dart';

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
        ? calcTotalSurvivorPension(input)
        : calcManualSurvivorPension(input);
    final gap = requiredTotal - existingCoverage - survivorPension;

    return DiagnosisResult(
      id: '${input.id}_result',
      inputId: input.id,
      calculatedAt: DateTime.now(),
      requiredAmount: requiredTotal,
      existingCoverage: existingCoverage,
      survivorPension: survivorPension,
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

int calcLivingExpense(DiagnosisInput input) {
  if (!input.hasSpouse && input.childrenAges.isEmpty) {
    return 0;
  }

  final coefficient = _livingExpenseCoefficient(input);
  final monthlySurvivorExpense = (input.monthlyExpense * coefficient).round();

  final yearsUntilYoungestIndependent =
      calcYearsUntilYoungestIndependent(input);
  final childRearingCost =
      monthlySurvivorExpense * 12 * yearsUntilYoungestIndependent;

  final retirementYears = calcRetirementYears(input, yearsUntilYoungestIndependent);
  final retirementMonthly = input.retirementMonthlyExpense;
  final retirementCost = retirementMonthly * 12 * max(0, retirementYears);

  return childRearingCost + retirementCost.round();
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

int calcRetirementYears(
  DiagnosisInput input,
  int yearsUntilYoungestIndependent,
) {
  if (!input.hasSpouse || input.spouseAge == null) return 0;

  final spouseLifeExpectancy = _estimateSpouseLifeExpectancy(input.spouseAge!);
  final yearsAfterIndependence = spouseLifeExpectancy -
      (input.spouseAge! + yearsUntilYoungestIndependent);
  return max(0, yearsAfterIndependence);
}

int _estimateSpouseLifeExpectancy(int spouseAge) {
  // 簡易: 現在年齢から平均余命を引いた残年数 + 現在年齢
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
  final retirementYears = calcRetirementYears(input, childYears);
  return childYears + retirementYears;
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

double calcSurvivorPensionAnnual(int annualIncome, int workingYears) {
  final monthlyStandardWage = (annualIncome * 10000) / 12;
  final insuredMonths = max(workingYears * 12, 300);
  final survivorPension = monthlyStandardWage *
      (5.481 / 1000) *
      insuredMonths *
      0.75;
  return survivorPension / 10000;
}

int calcChildAddition(int numChildren) {
  if (numChildren == 0) return 0;
  var addition = 0;
  for (var i = 0; i < numChildren; i++) {
    addition += i < 2 ? 23 : 8;
  }
  return addition;
}

int calcTotalSurvivorPension(DiagnosisInput input) {
  final annualPension = calcSurvivorPensionAnnual(
    input.annualIncome,
    input.workingYears ?? 20,
  ).round();
  final childAddition = calcChildAddition(input.childrenAges.length);
  final totalAnnual = annualPension + childAddition;
  final receivingYears = input.childrenAges.isEmpty
      ? 10
      : max(0, childIndependenceAge - input.youngestChildAge);
  return totalAnnual * receivingYears;
}

int calcManualSurvivorPension(DiagnosisInput input) {
  final annual = input.manualPensionAnnual ?? 0;
  final years = calcRemainingLivingYears(input);
  return annual * max(years, 1);
}

String buildAdviceText(DiagnosisResult result) {
  if (result.gap > 0) {
    final monthlyPremium = (result.gap * 0.0022).round();
    return '定期保険（掛捨型）で${result.gap}万円を確保すると、'
        '月々約${_formatPremium(monthlyPremium)}円〜が目安です。';
  }
  if (result.gap < 0) {
    return '現在の保障は必要額を上回っています。'
        '保険料の見直しで家計の余力を増やせる可能性があります。';
  }
  return '必要保障額と既存保障が概ね一致しています。'
      'ライフステージの変化に合わせて定期的な見直しをおすすめします。';
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
