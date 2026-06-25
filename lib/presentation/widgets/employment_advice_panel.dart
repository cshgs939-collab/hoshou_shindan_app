import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/employment_advice.dart';
import '../../core/utils/employment_labels.dart';
import '../../core/enums/pension_mode.dart';
import '../../data/models/diagnosis_input.dart';

/// 就業区分・年収に対する「公的年金で補えない分」の説明カード
class EmploymentAdvicePanel extends StatelessWidget {
  const EmploymentAdvicePanel({
    super.key,
    required this.input,
    this.showIncomeBreakdown = false,
    this.employmentType,
  });

  final DiagnosisInput input;
  final bool showIncomeBreakdown;
  final SpouseEmploymentType? employmentType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = employmentType ?? input.insuredWorkType;
    final coverage = describeInsuredIncomeCoverage(input);
    final placeholder = InsuredIncomeCoverage(
      annualIncomeMan: 0,
      monthlyIncomeMan: 0,
      monthlyPensionMan: 0,
      uncoveredMonthlyMan: 0,
      phaseLabel: '',
      hasKousei: insuredWorkTypeHasKousei(type),
    );

    final body = coverage != null && showIncomeBreakdown
        ? coverage.incomeGapExplanation()
        : placeholder.employmentTypeNote(type);

    final highlightUncovered =
        coverage != null && coverage.uncoveredMonthlyMan > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlightUncovered
            ? AppColors.error.withValues(alpha: 0.06)
            : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlightUncovered
              ? AppColors.error.withValues(alpha: 0.25)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 公的年金で補えない収入',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: highlightUncovered ? AppColors.error : AppColors.primary,
            ),
          ),
          if (coverage != null && showIncomeBreakdown) ...[
            const SizedBox(height: 10),
            _row(theme, 'あなたの年収', '年${coverage.annualIncomeMan}万円'),
            _row(
              theme,
              '月額に換算',
              '約${coverage.monthlyIncomeMan}万円/月',
            ),
            _row(
              theme,
              '遺族年金（概算）',
              '約${coverage.monthlyPensionMan}万円/月（${coverage.phaseLabel}）',
            ),
            if (coverage.uncoveredMonthlyMan > 0)
              _row(
                theme,
                '公的年金では補えない',
                '約${coverage.uncoveredMonthlyMan}万円/月',
                bold: true,
                color: AppColors.error,
              ),
            const SizedBox(height: 8),
          ],
          Text(
            body,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
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
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 配偶者就業に関する補足
class SpouseEmploymentAdvicePanel extends StatelessWidget {
  const SpouseEmploymentAdvicePanel({super.key, required this.input});

  final DiagnosisInput input;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = spouseWorkCoverageNote(input);
    if (note.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 配偶者の就労でカバーする分',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(note, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
