import 'dart:math';

import '../constants/pension_constants.dart';
import '../enums/pension_mode.dart';
import '../../data/models/diagnosis_input.dart';
import '../../domain/calculation/survivor_pension_calculator.dart';
import 'employment_labels.dart';

/// 世帯主の年収に対し、遺族年金でカバーできる／できない額
class InsuredIncomeCoverage {
  const InsuredIncomeCoverage({
    required this.annualIncomeMan,
    required this.monthlyIncomeMan,
    required this.monthlyPensionMan,
    required this.uncoveredMonthlyMan,
    required this.phaseLabel,
    required this.hasKousei,
  });

  final int annualIncomeMan;
  final int monthlyIncomeMan;
  final int monthlyPensionMan;
  final int uncoveredMonthlyMan;
  final String phaseLabel;
  final bool hasKousei;

  /// 就業区分のみ（年収未入力時）
  String employmentTypeNote(SpouseEmploymentType type) {
    switch (type) {
      case SpouseEmploymentType.fullTime:
      case SpouseEmploymentType.partTime:
        return '厚生年金に加入しているため遺族厚生年金が付きます。'
            'ただし年収の全額は公的年金では補えません。'
            '次の画面で年収を入力すると、補えない月額を表示します。';
      case SpouseEmploymentType.selfEmployed:
        return '遺族厚生年金は付きません。'
            '年収に相当する収入は、お子さんがいる場合の遺族基礎年金だけでは'
            'ほとんど補えません。生命保険等での備えが重要になります。';
      case SpouseEmploymentType.unemployed:
        return '厚生年金に加入していないため遺族厚生年金は付きません。'
            '年収がない場合も、万一前に働いていた期間の遺族年金は'
            'この区分では試算しません（勤続年数はステップ3で入力）。';
    }
  }

  /// 年収入力後の具体的な説明
  String incomeGapExplanation() {
    if (!hasKousei && monthlyPensionMan == 0) {
      return '年収${annualIncomeMan}万円（月${monthlyIncomeMan}万円相当）の多くは、'
          '遺族厚生年金がないため公的年金ではほとんど補えません。'
          '公的年金でカバーできない月${monthlyIncomeMan}万円相当は、'
          '生命保険等で備える必要があります。';
    }
    if (uncoveredMonthlyMan <= 0) {
      return '年収${annualIncomeMan}万円（月${monthlyIncomeMan}万円相当）に対し、'
          '遺族年金の概算（月${monthlyPensionMan}万円・$phaseLabel）は'
          '公的年金でおおむねカバーされる試算です。';
    }
    return '年収${annualIncomeMan}万円（月${monthlyIncomeMan}万円相当）のうち、'
        '公的年金（遺族年金）の概算は月${monthlyPensionMan}万円（$phaseLabel）です。'
        '年収のうち約${uncoveredMonthlyMan}万円/月は公的年金では補えません。'
        'この不足分を含め、生活費・教育費などと合わせて保障額を試算します。';
  }
}

InsuredIncomeCoverage? describeInsuredIncomeCoverage(DiagnosisInput input) {
  if (input.annualIncome <= 0) return null;

  final annualIncomeMan = input.annualIncome;
  final monthlyIncomeMan = max(1, (annualIncomeMan / 12).round());
  final hasKousei = insuredWorkTypeHasKousei(input.insuredWorkType);

  final phaseKind = _primaryPensionPhase(input);
  final monthlyPensionMan = max(
    0,
    (calcSurvivorPensionAnnualForPhase(input, phaseKind) / 12).round(),
  );
  final phaseLabel = _phaseLabel(input, phaseKind);
  final uncoveredMonthlyMan = max(0, monthlyIncomeMan - monthlyPensionMan);

  return InsuredIncomeCoverage(
    annualIncomeMan: annualIncomeMan,
    monthlyIncomeMan: monthlyIncomeMan,
    monthlyPensionMan: monthlyPensionMan,
    uncoveredMonthlyMan: uncoveredMonthlyMan,
    phaseLabel: phaseLabel,
    hasKousei: hasKousei,
  );
}

String insuredEmploymentIntro() =>
    '万一の際、あなたの収入の多くは失われます。'
    '公的年金（遺族年金）でカバーできる額と、補えない額を把握するための区分です。';

String spouseEmploymentIntro() =>
    '配偶者の就労収入は、公的年金で足りない生活費を補う想定です（65歳まで）。'
    'ただし、あなたの年収自体は公的年金では全額は置き換えられません。';

String spouseWorkCoverageNote(DiagnosisInput input) {
  if (!input.hasSpouse) return '';

  final workMonthly = estimateSurvivorWorkMonthly(input);
  if (workMonthly <= 0) {
    return '配偶者の就労想定がない場合、公的年金で足りない分は'
        'すべて生命保険等の保障が必要になります。';
  }

  final coverage = describeInsuredIncomeCoverage(input);
  if (coverage == null) {
    return '万一後は配偶者の就労を月${workMonthly}万円程度と想定し、'
        '公的年金で足りない生活費の一部をカバーします（65歳まで）。';
  }

  final afterWork = max(0, coverage.uncoveredMonthlyMan - workMonthly);
  if (afterWork <= 0) {
    return '万一後は配偶者の就労を月${workMonthly}万円と想定。'
        '公的年金で足りない年収分は、就労収入でおおむねカバーできる試算です'
        '（生活費・教育費などは別途必要）。';
  }

  return '万一後は配偶者の就労を月${workMonthly}万円と想定。'
      '公的年金で補えない年収分（約${coverage.uncoveredMonthlyMan}万円/月）のうち、'
      '就労で約${workMonthly}万円をカバー。'
      '残り約${afterWork}万円/月相当は生命保険等が必要です'
      '（生活費・教育費などは別途）。';
}

SurvivorPensionPhaseKind _primaryPensionPhase(DiagnosisInput input) {
  if (input.childrenAges.isNotEmpty && calcYearsUntilChild18End(input) > 0) {
    return SurvivorPensionPhaseKind.withChild;
  }
  if (input.hasSpouse && (input.spouseAge ?? input.age) < retirementStartAge) {
    return SurvivorPensionPhaseKind.afterChildBefore65;
  }
  return SurvivorPensionPhaseKind.afterChildBefore65;
}

String _phaseLabel(DiagnosisInput input, SurvivorPensionPhaseKind kind) {
  switch (kind) {
    case SurvivorPensionPhaseKind.withChild:
      return 'お子さんがいる期間';
    case SurvivorPensionPhaseKind.afterChildBefore65:
      return '配偶者が65歳になるまで';
    case SurvivorPensionPhaseKind.after65:
      return '65歳以降';
  }
}
