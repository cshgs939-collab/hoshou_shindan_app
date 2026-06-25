import 'dart:math';

import '../../core/constants/pension_constants.dart';
import '../../core/enums/pension_mode.dart';
import '../../core/utils/employment_labels.dart';
import '../../data/models/diagnosis_input.dart';

/// 遺族年金の受給フェーズ
enum SurvivorPensionPhaseKind {
  /// 子18歳年度末まで（基礎＋加算＋厚生）
  withChild,
  /// 子18歳後〜65歳前（厚生のみ）
  afterChildBefore65,
  /// 65歳以降（厚生・併給調整後）
  after65,
}

class SurvivorPensionPhase {
  const SurvivorPensionPhase({
    required this.kind,
    required this.years,
    required this.annualAmount,
  });

  final SurvivorPensionPhaseKind kind;
  final int years;
  final int annualAmount;

  int get total => annualAmount * years;
  int get monthly => max(0, (annualAmount / 12).round());
}

int calcYearsUntilChild18End(DiagnosisInput input) {
  if (input.childrenAges.isEmpty) return 0;
  if (input.youngestChildAge >= 18) return 0;
  return 18 - input.youngestChildAge;
}

int calcSurvivorWorkYears(DiagnosisInput input) {
  if (!input.hasSpouse || input.spouseAge == null) return 0;
  if (input.spouseAge! >= retirementStartAge) return 0;
  return retirementStartAge - input.spouseAge!;
}

int estimateSpouseLifeEndAge(int spouseAge) {
  final remaining = spouseAge < retirementStartAge ? 87 - spouseAge : 20;
  return spouseAge + remaining;
}

/// 配偶者の国民年金加入年数（第3号＋死亡後の第2号就労）
int estimateNationPensionYears(DiagnosisInput input) {
  if (!input.hasSpouse || input.spouseAge == null) return 0;
  final category3Years =
      max(0, input.spouseAge! - nationPensionCategory3StartAge);
  final category2Years = calcSurvivorWorkYears(input);
  return min(nationPensionFullYears, category3Years + category2Years);
}

/// 老齢基礎年金（万円/年）。65歳からの国民年金分。
int estimateOldAgeBasicAnnual(DiagnosisInput input) {
  if (!input.hasSpouse) return 0;
  final years = estimateNationPensionYears(input);
  return (oldAgeBasicPensionFullAnnual * years / nationPensionFullYears)
      .round();
}

/// 配偶者自身の老齢厚生年金（死亡後の第2号就労から概算・万円/年）
int estimateSpouseOldAgeKouseiAnnual(DiagnosisInput input) {
  if (!input.hasSpouse) return 0;
  final workYears = calcSurvivorWorkYears(input);
  if (workYears <= 0) return 0;
  return calcSurvivorKouseiFromIncome(
    estimateSurvivorWorkAnnual(input),
    workYears,
  ).round();
}

/// 65歳以降の公的年金（老齢基礎＋遺族/老齢厚生の併給調整後）
int calcAfter65PensionAnnual(DiagnosisInput input) {
  if (input.survivorPensionMode == SurvivorPensionMode.manual) {
    return (input.manualPensionAnnual ?? 0) + estimateOldAgeBasicAnnual(input);
  }

  final oldAgeBasic = estimateOldAgeBasicAnnual(input);
  final survivorKousei = calcSurvivorKouseiAnnual(input);
  final spouseKousei = estimateSpouseOldAgeKouseiAnnual(input);
  final kouseiPart = max(survivorKousei, spouseKousei);
  return oldAgeBasic + kouseiPart;
}

/// 配偶者の就労想定年収（万円/年）。世帯主死亡後は就労増を前提。
int estimateSurvivorWorkAnnual(DiagnosisInput input) {
  if (!input.hasSpouse) return 0;

  switch (input.employmentType) {
    case SpouseEmploymentType.unemployed:
      return max(input.spouseIncome, assumedSurvivorWorkIncomeAnnual);
    case SpouseEmploymentType.partTime:
      return max(
        (input.spouseIncome * 1.25).round(),
        minimumSurvivorWorkIncomeAnnual,
      );
    case SpouseEmploymentType.fullTime:
      return input.spouseIncome;
    case SpouseEmploymentType.selfEmployed:
      return max(input.spouseIncome, minimumSurvivorWorkIncomeAnnual);
  }
}

int estimateSurvivorWorkMonthly(DiagnosisInput input) {
  return max(0, (estimateSurvivorWorkAnnual(input) / 12).round());
}

int calcTotalSurvivorWorkIncome(DiagnosisInput input) {
  final years = calcSurvivorWorkYears(input);
  if (years <= 0) return 0;
  return estimateSurvivorWorkMonthly(input) * 12 * years;
}

int calcChildAdditionAnnual(int numChildren) {
  if (numChildren <= 0) return 0;
  var addition = 0;
  for (var i = 0; i < numChildren; i++) {
    addition +=
        i < 2 ? survivorChildAdditionFirst : survivorChildAdditionExtra;
  }
  return addition;
}

/// 遺族厚生年金（万円/年）。自営業・無職の場合は0。
int calcSurvivorKouseiAnnual(DiagnosisInput input) {
  if (!insuredWorkTypeHasKousei(input.insuredWorkType)) {
    return 0;
  }
  if (input.survivorPensionMode == SurvivorPensionMode.manual) {
    return input.manualPensionAnnual ?? 0;
  }
  return calcSurvivorKouseiFromIncome(
    input.annualIncome,
    input.workingYears ?? 20,
  ).round();
}

double calcSurvivorKouseiFromIncome(int annualIncome, int workingYears) {
  final monthlyStandardWage = (annualIncome * 10000) / 12;
  final insuredMonths = max(workingYears * 12, 300);
  final survivorPension = monthlyStandardWage *
      (5.481 / 1000) *
      insuredMonths *
      0.75;
  return survivorPension / 10000;
}

int calcSurvivorPensionAnnualForPhase(
  DiagnosisInput input,
  SurvivorPensionPhaseKind kind,
) {
  if (input.survivorPensionMode == SurvivorPensionMode.manual) {
    return input.manualPensionAnnual ?? 0;
  }

  final kousei = calcSurvivorKouseiAnnual(input);
  final hasChildren = input.childrenAges.isNotEmpty;

  switch (kind) {
    case SurvivorPensionPhaseKind.withChild:
      if (!hasChildren) return kousei;
      return survivorBasicPensionAnnual +
          calcChildAdditionAnnual(input.childrenAges.length) +
          kousei;
    case SurvivorPensionPhaseKind.afterChildBefore65:
      return kousei;
    case SurvivorPensionPhaseKind.after65:
      return calcAfter65PensionAnnual(input);
  }
}

List<SurvivorPensionPhase> calcSurvivorPensionPhases(DiagnosisInput input) {
  if (input.survivorPensionMode == SurvivorPensionMode.manual) {
    final years = _totalPensionYears(input);
    return [
      SurvivorPensionPhase(
        kind: SurvivorPensionPhaseKind.afterChildBefore65,
        years: max(years, 1),
        annualAmount: input.manualPensionAnnual ?? 0,
      ),
    ];
  }

  if (!input.hasSpouse && input.childrenAges.isEmpty) return [];

  final spouseAge = input.spouseAge ?? input.age;
  final childYears = calcYearsUntilChild18End(input);
  final yearsTo65 = spouseAge >= retirementStartAge
      ? 0
      : retirementStartAge - spouseAge;
  final retirementYears = _estimateRetirementYears(spouseAge);

  final childPhaseYears = min(childYears, yearsTo65 + retirementYears);
  final afterChildBefore65Years = max(0, yearsTo65 - childPhaseYears);

  final phases = <SurvivorPensionPhase>[];
  if (childPhaseYears > 0) {
    phases.add(
      SurvivorPensionPhase(
        kind: SurvivorPensionPhaseKind.withChild,
        years: childPhaseYears,
        annualAmount: calcSurvivorPensionAnnualForPhase(
          input,
          SurvivorPensionPhaseKind.withChild,
        ),
      ),
    );
  }
  if (afterChildBefore65Years > 0) {
    phases.add(
      SurvivorPensionPhase(
        kind: SurvivorPensionPhaseKind.afterChildBefore65,
        years: afterChildBefore65Years,
        annualAmount: calcSurvivorPensionAnnualForPhase(
          input,
          SurvivorPensionPhaseKind.afterChildBefore65,
        ),
      ),
    );
  }
  if (retirementYears > 0) {
    phases.add(
      SurvivorPensionPhase(
        kind: SurvivorPensionPhaseKind.after65,
        years: retirementYears,
        annualAmount: calcSurvivorPensionAnnualForPhase(
          input,
          SurvivorPensionPhaseKind.after65,
        ),
      ),
    );
  }
  return phases;
}

int calcTotalSurvivorPensionLifetime(DiagnosisInput input) {
  return calcSurvivorPensionPhases(input)
      .fold(0, (sum, phase) => sum + phase.total);
}

int _totalPensionYears(DiagnosisInput input) {
  final childYears = calcYearsUntilChild18End(input);
  final workYears = calcSurvivorWorkYears(input);
  final retirementYears = _estimateRetirementYears(input.spouseAge ?? input.age);
  return workYears + retirementYears + childYears;
}

int _estimateRetirementYears(int spouseAge) {
  final lifeEndAge = estimateSpouseLifeEndAge(spouseAge);
  if (lifeEndAge <= retirementStartAge) return 0;
  if (spouseAge >= retirementStartAge) return lifeEndAge - spouseAge;
  return lifeEndAge - retirementStartAge;
}
