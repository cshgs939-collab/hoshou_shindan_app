import 'dart:math';

import '../../data/models/diagnosis_input.dart';
import 'calculation_engine.dart';
import 'survivor_pension_calculator.dart';

/// 保障が必要な期間と定期保険の残り期間
class InsurancePeriodSummary {
  const InsurancePeriodSummary({
    required this.yearsUntilChild18,
    required this.yearsUntilChildIndependent,
    required this.yearsUntilSpouse65,
    required this.recommendedYears,
    this.termInsuranceEndAge,
    this.termRemainingYears,
  });

  factory InsurancePeriodSummary.from(DiagnosisInput input) {
    final yearsUntilChild18 = calcYearsUntilChild18End(input);
    final yearsUntilChildIndependent = calcYearsUntilYoungestIndependent(input);
    final yearsUntilSpouse65 = calcSurvivorWorkYears(input);
    final recommendedYears = calcRecommendedInsuranceYears(input);
    final termEndAge = input.termInsuranceEndAge;
    final termRemaining = calcTermInsuranceRemainingYears(input);

    return InsurancePeriodSummary(
      yearsUntilChild18: yearsUntilChild18,
      yearsUntilChildIndependent: yearsUntilChildIndependent,
      yearsUntilSpouse65: yearsUntilSpouse65,
      recommendedYears: recommendedYears,
      termInsuranceEndAge: termEndAge > 0 ? termEndAge : null,
      termRemainingYears: termRemaining,
    );
  }

  final int yearsUntilChild18;
  final int yearsUntilChildIndependent;
  final int yearsUntilSpouse65;
  final int recommendedYears;
  final int? termInsuranceEndAge;
  final int? termRemainingYears;

  bool get hasTermInsurancePeriod =>
      termRemainingYears != null && termInsuranceEndAge != null;

  bool get termCoversRecommended =>
      !hasTermInsurancePeriod ||
      termRemainingYears! >= recommendedYears;

  int? get termShortfallYears => hasTermInsurancePeriod && !termCoversRecommended
      ? recommendedYears - termRemainingYears!
      : null;
}

/// 定期保険の保障期間の目安（最も長い必要期間）
int calcRecommendedInsuranceYears(DiagnosisInput input) {
  final child18 = calcYearsUntilChild18End(input);
  final childIndep = calcYearsUntilYoungestIndependent(input);
  final spouse65 = calcSurvivorWorkYears(input);
  return max(max(child18, childIndep), spouse65);
}

/// 定期保険の残り保障年数（終了年齢 − 現在年齢）
int? calcTermInsuranceRemainingYears(DiagnosisInput input) {
  if (input.termInsurance <= 0 || input.termInsuranceEndAge <= 0) {
    return null;
  }
  return max(0, input.termInsuranceEndAge - input.age);
}
