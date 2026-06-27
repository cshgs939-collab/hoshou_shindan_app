import 'dart:math';

import '../../core/constants/app_explanations.dart';
import '../../core/constants/pension_constants.dart';
import '../../core/enums/pension_mode.dart';
import '../../core/utils/employment_labels.dart';
import '../../data/models/diagnosis_input.dart';
import 'survivor_pension_calculator.dart';

/// 65歳から受け取れる公的年金の概算（健在前提）
class OldAgePensionEstimate {
  const OldAgePensionEstimate({
    required this.roleLabel,
    required this.basicAnnualMan,
    required this.kouseiAnnualMan,
    required this.nationYears,
    required this.kouseiYears,
    required this.hasKousei,
    required this.yearsUntilStart,
    required this.alreadyAtOrPastStart,
  });

  final String roleLabel;
  final int basicAnnualMan;
  final int kouseiAnnualMan;
  final int nationYears;
  final int kouseiYears;
  final bool hasKousei;
  final int yearsUntilStart;
  final bool alreadyAtOrPastStart;

  int get totalAnnualMan => basicAnnualMan + kouseiAnnualMan;

  int get basicMonthlyMan => max(0, (basicAnnualMan / 12).round());

  int get kouseiMonthlyMan => max(0, (kouseiAnnualMan / 12).round());

  int get totalMonthlyMan => max(0, (totalAnnualMan / 12).round());
}

int effectiveInsuredWorkingYears(DiagnosisInput input) {
  return input.workingYears ?? defaultWorkingYearsFromAge(input.age);
}

int effectiveSpouseWorkingYears(DiagnosisInput input) {
  if (!input.hasSpouse || input.spouseAge == null) return 0;
  return min(40, max(1, input.spouseAge! - 22));
}

int defaultWorkingYearsFromAge(int age) {
  return min(nationPensionFullYears, max(1, age - 22));
}

int estimateInsuredNationYears(DiagnosisInput input) {
  final workingYears = effectiveInsuredWorkingYears(input);
  switch (input.insuredWorkType) {
    case SpouseEmploymentType.fullTime:
    case SpouseEmploymentType.partTime:
      return min(nationPensionFullYears, workingYears);
    case SpouseEmploymentType.selfEmployed:
      return min(
        nationPensionFullYears,
        max(workingYears, defaultWorkingYearsFromAge(input.age)),
      );
    case SpouseEmploymentType.unemployed:
      return min(
        nationPensionFullYears,
        max(1, (input.age - nationPensionCategory3StartAge).clamp(1, 25)),
      );
  }
}

int estimateSpouseAliveNationYears(DiagnosisInput input) {
  if (!input.hasSpouse || input.spouseAge == null) return 0;
  final spouseAge = input.spouseAge!;
  switch (input.employmentType) {
    case SpouseEmploymentType.fullTime:
    case SpouseEmploymentType.partTime:
    case SpouseEmploymentType.selfEmployed:
      return min(
        nationPensionFullYears,
        max(effectiveSpouseWorkingYears(input), defaultWorkingYearsFromAge(spouseAge)),
      );
    case SpouseEmploymentType.unemployed:
      return min(
        nationPensionFullYears,
        max(0, spouseAge - nationPensionCategory3StartAge),
      );
  }
}

/// 老齢厚生年金（万円/年）。遺族厚生の 4/3 倍相当の簡易概算。
double calcOldAgeKouseiFromIncome(int annualIncomeMan, int workingYears) {
  return calcSurvivorKouseiFromIncome(annualIncomeMan, workingYears) / 0.75;
}

int estimateInsuredOldAgeBasicAnnual(DiagnosisInput input) {
  final years = estimateInsuredNationYears(input);
  return (oldAgeBasicPensionFullAnnual * years / nationPensionFullYears)
      .round();
}

int estimateInsuredOldAgeKouseiAnnual(DiagnosisInput input) {
  if (!insuredWorkTypeHasKousei(input.insuredWorkType)) return 0;
  if (input.annualIncome <= 0) return 0;
  return calcOldAgeKouseiFromIncome(
    input.annualIncome,
    effectiveInsuredWorkingYears(input),
  ).round();
}

int estimateSpouseAliveOldAgeBasicAnnual(DiagnosisInput input) {
  if (!input.hasSpouse) return 0;
  final years = estimateSpouseAliveNationYears(input);
  return (oldAgeBasicPensionFullAnnual * years / nationPensionFullYears)
      .round();
}

int estimateSpouseAliveOldAgeKouseiAnnual(DiagnosisInput input) {
  if (!input.hasSpouse) return 0;
  if (!insuredWorkTypeHasKousei(input.employmentType)) return 0;

  final income = input.spouseIncome > 0
      ? input.spouseIncome
      : switch (input.employmentType) {
          SpouseEmploymentType.partTime => minimumSurvivorWorkIncomeAnnual,
          SpouseEmploymentType.unemployed => 0,
          _ => minimumSurvivorWorkIncomeAnnual,
        };
  if (income <= 0) return 0;

  return calcOldAgeKouseiFromIncome(
    income,
    effectiveSpouseWorkingYears(input),
  ).round();
}

OldAgePensionEstimate estimateInsuredOldAgePension(DiagnosisInput input) {
  final yearsUntilStart =
      max(0, retirementStartAge - input.age);
  return OldAgePensionEstimate(
    roleLabel: 'あなた',
    basicAnnualMan: estimateInsuredOldAgeBasicAnnual(input),
    kouseiAnnualMan: estimateInsuredOldAgeKouseiAnnual(input),
    nationYears: estimateInsuredNationYears(input),
    kouseiYears: insuredWorkTypeHasKousei(input.insuredWorkType)
        ? effectiveInsuredWorkingYears(input)
        : 0,
    hasKousei: insuredWorkTypeHasKousei(input.insuredWorkType),
    yearsUntilStart: yearsUntilStart,
    alreadyAtOrPastStart: input.age >= retirementStartAge,
  );
}

OldAgePensionEstimate? estimateSpouseOldAgePension(DiagnosisInput input) {
  if (!input.hasSpouse || input.spouseAge == null) return null;
  final spouseAge = input.spouseAge!;
  final yearsUntilStart = max(0, retirementStartAge - spouseAge);
  return OldAgePensionEstimate(
    roleLabel: '配偶者',
    basicAnnualMan: estimateSpouseAliveOldAgeBasicAnnual(input),
    kouseiAnnualMan: estimateSpouseAliveOldAgeKouseiAnnual(input),
    nationYears: estimateSpouseAliveNationYears(input),
    kouseiYears: insuredWorkTypeHasKousei(input.employmentType)
        ? effectiveSpouseWorkingYears(input)
        : 0,
    hasKousei: insuredWorkTypeHasKousei(input.employmentType),
    yearsUntilStart: yearsUntilStart,
    alreadyAtOrPastStart: spouseAge >= retirementStartAge,
  );
}

class RetirementPensionGap {
  const RetirementPensionGap({
    required this.needMonthlyMan,
    required this.pensionMonthlyMan,
    required this.gapMonthlyMan,
    required this.householdLabel,
    required this.isSingleParent,
  });

  final int needMonthlyMan;
  final int pensionMonthlyMan;
  final int gapMonthlyMan;
  final String householdLabel;
  final bool isSingleParent;

  bool get hasShortfall => gapMonthlyMan > 0;
}

RetirementPensionGap calcRetirementPensionGap(DiagnosisInput input) {
  final insured = estimateInsuredOldAgePension(input);
  final spouse = estimateSpouseOldAgePension(input);
  final pensionMonthly =
      insured.totalMonthlyMan + (spouse?.totalMonthlyMan ?? 0);
  final need = input.retirementMonthlyExpense;
  final isSingleParent = !input.hasSpouse && input.childrenAges.isNotEmpty;

  final householdLabel = switch ((input.hasSpouse, input.childrenAges.isEmpty)) {
    (false, true) => '単身世帯',
    (false, false) => 'ひとり親世帯（あなた＋お子さん）',
    (true, true) => '夫婦世帯',
    (true, false) => '夫婦＋お子さん世帯',
  };

  return RetirementPensionGap(
    needMonthlyMan: need,
    pensionMonthlyMan: pensionMonthly,
    gapMonthlyMan: max(0, need - pensionMonthly),
    householdLabel: householdLabel,
    isSingleParent: isSingleParent,
  );
}

String oldAgePensionIntro(DiagnosisInput input) =>
    AppExplanations.oldAgePensionLead(input);

String formatOldAgePensionSummary(OldAgePensionEstimate estimate) {
  final startLabel = estimate.alreadyAtOrPastStart
      ? '${retirementStartAge}歳以降（現在）'
      : 'あと${estimate.yearsUntilStart}年後（${retirementStartAge}歳から）';
  final kouseiPart = estimate.hasKousei && estimate.kouseiAnnualMan > 0
      ? '老齢厚生 約${estimate.kouseiMonthlyMan}万円/月、'
      : estimate.hasKousei
          ? '老齢厚生 試算少、'
          : '';
  return '${estimate.roleLabel}：老齢基礎 約${estimate.basicMonthlyMan}万円/月、'
      '$kouseiPart'
      '合計 約${estimate.totalMonthlyMan}万円/月（$startLabel）。';
}
