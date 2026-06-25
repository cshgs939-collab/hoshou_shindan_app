import '../../data/models/diagnosis_input.dart';
import '../../data/models/diagnosis_result.dart';
import '../../domain/calculation/calculation_engine.dart';
import '../../domain/calculation/survivor_pension_calculator.dart';

/// 65歳以降の生活費と、保障（保険）が必要な残額の説明用データ
class RetirementGuaranteeSummary {
  const RetirementGuaranteeSummary({
    required this.retirementYears,
    required this.needMonthlyMan,
    required this.oldAgeBasicMonthlyMan,
    required this.kouseiMonthlyMan,
    required this.pensionMonthlyMan,
    required this.monthlyShortfallMan,
    required this.livingShortfallTotalMan,
    required this.nonLivingRequiredMan,
    required this.guaranteeNeededMan,
  });

  factory RetirementGuaranteeSummary.from({
    required DiagnosisInput input,
    required DiagnosisResult result,
  }) {
    final oldAgeBasic = estimateOldAgeBasicAnnual(input);
    final survivorKousei = calcSurvivorKouseiAnnual(input);
    final spouseKousei = estimateSpouseOldAgeKouseiAnnual(input);
    final kouseiPart = survivorKousei > spouseKousei
        ? survivorKousei
        : spouseKousei;
    final pensionAnnual = calcAfter65PensionAnnual(input);
    final pensionMonthlyMan = pensionAnnual / 12;
    final oldAgeBasicMonthlyMan = oldAgeBasic / 12;
    final kouseiMonthlyMan = kouseiPart / 12;
    final needMonthlyMan = input.retirementMonthlyExpense.toDouble();
    // 65歳以降の就労は見込まない（公的年金のみ差し引き）
    final monthlyShortfallMan =
        (needMonthlyMan - pensionMonthlyMan).clamp(0.0, 9999.0);
    final retirementYears = calcRetirementYears(input);
    final livingShortfallTotalMan = calcRetirementLivingExpense(input);
    final nonLivingRequiredMan = result.educationFee +
        result.housingFee +
        result.funeralFee;

    return RetirementGuaranteeSummary(
      retirementYears: retirementYears,
      needMonthlyMan: needMonthlyMan,
      oldAgeBasicMonthlyMan: oldAgeBasicMonthlyMan,
      kouseiMonthlyMan: kouseiMonthlyMan,
      pensionMonthlyMan: pensionMonthlyMan,
      monthlyShortfallMan: monthlyShortfallMan,
      livingShortfallTotalMan: livingShortfallTotalMan,
      nonLivingRequiredMan: nonLivingRequiredMan,
      guaranteeNeededMan: result.gap,
    );
  }

  final int retirementYears;
  final double needMonthlyMan;
  final double oldAgeBasicMonthlyMan;
  final double kouseiMonthlyMan;
  final double pensionMonthlyMan;
  final double monthlyShortfallMan;
  final int livingShortfallTotalMan;
  final int nonLivingRequiredMan;
  final int guaranteeNeededMan;

  int get monthlyShortfallYen => (monthlyShortfallMan * 10000).round();

  int get livingShortfallTotalYen => livingShortfallTotalMan * 10000;

  int get totalGuaranteeBeforeExistingMan =>
      livingShortfallTotalMan + nonLivingRequiredMan;
}
