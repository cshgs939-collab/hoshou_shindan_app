import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/pension_constants.dart';
import '../../data/models/diagnosis_input.dart';
import '../../domain/calculation/insurance_period.dart';

/// ステップ1の年齢から、保障が必要な年数を表示
class InsurancePeriodPanel extends StatelessWidget {
  const InsurancePeriodPanel({super.key, required this.input});

  final DiagnosisInput input;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = InsurancePeriodSummary.from(input);

    return Card(
      color: AppColors.secondary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 保障が必要な期間（年齢から自動計算）',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'あなた ${input.age}歳'
              '${input.hasSpouse && input.spouseAge != null ? ' / 配偶者 ${input.spouseAge}歳' : ''}'
              '${input.childrenAges.isNotEmpty ? ' / お子さん ${input.youngestChildAge}歳' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (summary.yearsUntilChild18 > 0)
              _line('お子さんが18歳になるまで', summary.yearsUntilChild18),
            if (summary.yearsUntilChildIndependent > 0)
              _line('お子さんが22歳（自立）まで', summary.yearsUntilChildIndependent),
            if (summary.yearsUntilSpouse65 > 0)
              _line('配偶者が${retirementStartAge}歳になるまで', summary.yearsUntilSpouse65),
            const Divider(height: 16),
            Text(
              '定期保険の目安：約 ${summary.recommendedYears} 年以上',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (summary.hasTermInsurancePeriod) ...[
              const SizedBox(height: 8),
              Text(
                '定期保険の残り：${summary.termRemainingYears}年'
                '（${summary.termInsuranceEndAge}歳まで）',
                style: theme.textTheme.bodyMedium,
              ),
              if (summary.termCoversRecommended)
                Text(
                  '→ 目安期間をカバーしています',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                  ),
                )
              else
                Text(
                  '→ 目安より ${summary.termShortfallYears} 年不足しています',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(String label, int years) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('・$label：約${years}年', style: const TextStyle(fontSize: 13)),
    );
  }
}
