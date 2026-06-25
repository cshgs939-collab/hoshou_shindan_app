import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/pension_constants.dart';
import '../../core/utils/formatter.dart';
import '../../data/models/diagnosis_input.dart';
import '../../data/models/diagnosis_result.dart';
import '../../domain/calculation/calculation_engine.dart';
import '../../domain/calculation/retirement_guarantee_summary.dart';
import '../../domain/calculation/survivor_pension_calculator.dart';

/// 診断結果の計算根拠をユーザー向けに説明するパネル
class CalculationExplanationPanel extends StatelessWidget {
  const CalculationExplanationPanel({
    super.key,
    required this.input,
    required this.result,
  });

  final DiagnosisInput input;
  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final after65 = _After65Summary.from(input);
    final guarantee = input.hasSpouse
        ? RetirementGuaranteeSummary.from(input: input, result: result)
        : null;

    return Card(
      color: AppColors.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 計算の考え方',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '65歳前は「必要額 − 遺族年金 − 配偶者就労」、'
              '65歳以降は「必要額 − 公的年金のみ」（就労は見込まない）で'
              '不足分を算出します。教育費・住居費・葬儀費は別枠です。',
              style: theme.textTheme.bodyMedium,
            ),
            if (guarantee != null) ...[
              const SizedBox(height: 16),
              _GuaranteeHighlight(summary: guarantee),
            ],
            const SizedBox(height: 16),
            _Section(
              title: '生活費不足分',
              lines: [
                '式：65歳前＝（必要 − 遺族年金 − 就労）× 年数',
                '式：65歳後＝（必要 − 公的年金）× 年数 ※就労は見込まない',
                '65歳前：${formatManYen(calcPreRetirementLivingExpense(input))}',
                '65歳後：${formatManYen(calcRetirementLivingExpense(input))}',
                '合計：${formatManYen(result.livingExpense)}',
              ],
            ),
            if (input.hasSpouse) ...[
              const SizedBox(height: 12),
              _Section(
                title: '65歳まで（配偶者就労を反映）',
                lines: [
                  '就労想定：月${estimateSurvivorWorkMonthly(input)}万円'
                      '（年${estimateSurvivorWorkAnnual(input)}万円）',
                  '遺族年金は子の人数・18歳年度末・会社員/自営で変動',
                  'この期間の不足：'
                      '${formatManYen(calcPreRetirementLivingExpense(input))}',
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: '65歳以降（老齢基礎年金のみ差し引き）',
                lines: after65.lines,
              ),
            ],
            const SizedBox(height: 12),
            _Section(
              title: '保障が必要な額（費目別）',
              lines: [
                '生活費・65歳まで：${formatManYen(calcPreRetirementLivingExpense(input))}',
                '生活費・65歳以降：${formatManYen(calcRetirementLivingExpense(input))}',
                '　（${formatYen((guarantee?.monthlyShortfallYen ?? 0))}/月'
                ' × ${guarantee?.retirementYears ?? calcRetirementYears(input)}年）',
                '生活費 計：${formatManYen(result.livingExpense)}',
                '教育費：${formatManYen(result.educationFee)}',
                '住居費：${formatManYen(result.housingFee)}',
                '葬儀等：${formatManYen(result.funeralFee)}',
                '合計：${formatManYen(result.requiredAmount)}',
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: '不足額',
              lines: [
                '− 既存保障：${formatManYen(result.existingCoverage)}',
                '＝ 不足額：${formatManYen(result.gap)}',
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '※ 公的年金（${formatManYen(result.survivorPension)}）・'
              '配偶者就労（${formatManYen(result.survivorWorkIncome)}・65歳まで）'
              'は生活費不足分に反映済みです。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '※ 試算は概算です。実際の年金額は加入歴・併給調整・制度改正で変わります。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 65歳以降の「生活費 − 公的年金 ＝ 保障の残額」を強調表示
class _GuaranteeHighlight extends StatelessWidget {
  const _GuaranteeHighlight({required this.summary});

  final RetirementGuaranteeSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final years = summary.retirementYears;
    final monthlyShortfallYen = summary.monthlyShortfallYen;
    final totalYen = summary.livingShortfallTotalYen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🛡️ 65歳以降：保障が必要な残額',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '約${years}年間（${retirementStartAge}歳〜）・就労収入は見込みません',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 12),
          _moneyRow('① 毎月の生活費', summary.needMonthlyMan),
          _moneyRow('② 公的年金（65歳から）', summary.pensionMonthlyMan),
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text(
              '老齢基礎年金 ${formatYenMonthlyFromMan(summary.oldAgeBasicMonthlyMan)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text(
              '厚生年金 ${formatYenMonthlyFromMan(summary.kouseiMonthlyMan)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const Divider(height: 20),
          _moneyRow(
            '③ 毎月の不足（①−②）',
            summary.monthlyShortfallMan,
            bold: true,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '生活費で保障が必要な額',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatYen(monthlyShortfallYen)}/月'
                  ' × 12ヶ月 × ${years}年',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '＝ ${formatYen(totalYen)}（${formatManYen(summary.livingShortfallTotalMan)}）',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '【保障が必要な残額（全体）】',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '・老後の生活費不足：${formatManYen(summary.livingShortfallTotalMan)}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            '・教育費＋住居費＋葬儀等：${formatManYen(summary.nonLivingRequiredMan)}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            '・合計：${formatManYen(summary.totalGuaranteeBeforeExistingMan)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '公的年金で生活費の一部は賄えますが、'
            '残り ${formatManYen(summary.livingShortfallTotalMan)} 分は'
            '生命保険等の保障が必要です。'
            'さらに教育費・住居費も別途必要です。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '既存保障を差し引いた不足額：${formatManYen(summary.guaranteeNeededMan)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, num amountMan, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${formatYenMonthlyFromMan(amountMan)}/月',
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 6),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ],
    );
  }
}

class _After65Summary {
  _After65Summary({required this.lines});

  factory _After65Summary.from(DiagnosisInput input) {
    final oldAgeBasic = estimateOldAgeBasicAnnual(input);
    final survivorKousei = calcSurvivorKouseiAnnual(input);
    final spouseKousei = estimateSpouseOldAgeKouseiAnnual(input);
    final kouseiPart = survivorKousei > spouseKousei
        ? survivorKousei
        : spouseKousei;
    final pensionAnnual = calcAfter65PensionAnnual(input);
    final pensionMonthly = pensionAnnual / 12;
    final needMonthly = input.retirementMonthlyExpense;
    final retirementYears = calcRetirementYears(input);
    final shortfall = calcRetirementLivingExpense(input);

    final kouseiLabel = survivorKousei >= spouseKousei
        ? '遺族厚生${survivorKousei}万/年'
        : '老齢厚生${spouseKousei}万/年（就労より）';

    return _After65Summary(
      lines: [
        '老齢基礎年金：${formatYenMonthlyFromMan(oldAgeBasic / 12)}/月',
        '厚生年金（併給後）：${formatYenMonthlyFromMan(kouseiPart / 12)}/月（$kouseiLabel）',
        '公的年金合計：${formatYenMonthlyFromMan(pensionMonthly)}/月'
            '（${retirementYears}年間・${retirementStartAge}歳から）',
        '老後生活費想定：${formatYenMonthlyFromMan(needMonthly)}/月',
        '毎月の不足：${formatYenMonthlyFromMan(needMonthly - pensionMonthly)}',
        '→ 老後の生活費不足：${formatManYen(shortfall)}'
            '（就労は見込まない）',
      ],
    );
  }

  final List<String> lines;
}
