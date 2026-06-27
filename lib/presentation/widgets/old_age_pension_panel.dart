import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_explanations.dart';
import '../../core/constants/pension_constants.dart';
import '../../data/models/diagnosis_input.dart';
import '../../domain/calculation/old_age_pension_calculator.dart';

/// 65歳まで健在な場合の老齢年金概算
class OldAgePensionPanel extends StatelessWidget {
  const OldAgePensionPanel({
    super.key,
    required this.input,
    this.compact = false,
  });

  final DiagnosisInput input;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insured = estimateInsuredOldAgePension(input);
    final spouse = estimateSpouseOldAgePension(input);
    final gap = calcRetirementPensionGap(input);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gap.isSingleParent
                ? '🏛️ あなたの老後収入（${retirementStartAge}歳から・概算）'
                : '🏛️ ${retirementStartAge}歳からの公的年金（概算）',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              AppExplanations.oldAgePensionLead(input),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...AppExplanations.oldAgePensionBullets().map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '・$line',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _PersonEstimate(theme: theme, estimate: insured),
          if (spouse != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _PersonEstimate(theme: theme, estimate: spouse),
          ],
          const SizedBox(height: 12),
          _RetirementGapSection(theme: theme, gap: gap),
          const SizedBox(height: 8),
          Text(
            '※ 繰上げ・繰下げ（60〜75歳）は未反映。'
            '実際の額は年金定期便等でご確認ください。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetirementGapSection extends StatelessWidget {
  const _RetirementGapSection({
    required this.theme,
    required this.gap,
  });

  final ThemeData theme;
  final RetirementPensionGap gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gap.hasShortfall
            ? AppColors.error.withValues(alpha: 0.06)
            : AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: gap.hasShortfall
              ? AppColors.error.withValues(alpha: 0.2)
              : AppColors.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 老後生活費と老齢年金の差額（${gap.householdLabel}）',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _row('老後生活費想定', '${gap.needMonthlyMan}万円/月'),
          _row('老齢年金合計', '約${gap.pensionMonthlyMan}万円/月'),
          _row(
            gap.hasShortfall ? '毎月の不足' : '毎月の余力',
            gap.hasShortfall
                ? '約${gap.gapMonthlyMan}万円/月'
                : '約${gap.gapMonthlyMan}万円/月（概ね足りる）',
            highlight: true,
          ),
          const SizedBox(height: 6),
          Text(
            AppExplanations.retirementGapExplanation(gap),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: highlight && gap.hasShortfall ? AppColors.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonEstimate extends StatelessWidget {
  const _PersonEstimate({
    required this.theme,
    required this.estimate,
  });

  final ThemeData theme;
  final OldAgePensionEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final startText = estimate.alreadyAtOrPastStart
        ? '${retirementStartAge}歳以降'
        : '${retirementStartAge}歳から（あと${estimate.yearsUntilStart}年）';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          estimate.roleLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        _row('老齢基礎年金', '約${estimate.basicMonthlyMan}万円/月'
            '（加入${estimate.nationYears}年想定）'),
        if (estimate.hasKousei)
          _row(
            '老齢厚生年金',
            estimate.kouseiAnnualMan > 0
                ? '約${estimate.kouseiMonthlyMan}万円/月'
                    '（${estimate.kouseiYears}年想定）'
                : '年収未入力のため試算できません',
          )
        else
          _row('老齢厚生年金', '厚生年金未加入のため0'),
        _row(
          '合計',
          '約${estimate.totalMonthlyMan}万円/月',
          bold: true,
        ),
        _row('受給開始', startText),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: bold ? AppColors.secondary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
