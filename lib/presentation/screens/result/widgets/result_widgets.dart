import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatter.dart';
import '../../../../data/models/diagnosis_input.dart';
import '../../../../data/models/diagnosis_result.dart';
import '../../../../domain/calculation/calculation_engine.dart';
import '../../../../domain/calculation/retirement_guarantee_summary.dart';
import '../../../widgets/animated_widgets.dart';

class CoverageBarChart extends StatelessWidget {
  const CoverageBarChart({super.key, required this.result});

  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('生活', result.livingExpense.toDouble(), AppColors.living),
      ('教育', result.educationFee.toDouble(), AppColors.education),
      ('住居', result.housingFee.toDouble(), AppColors.housing),
      ('葬儀等', result.funeralFee.toDouble(), AppColors.funeral),
    ];

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: result.requiredAmount.toDouble() * 1.1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= categories.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(categories[index].$1,
                        style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(categories.length, (index) {
            final required = categories[index].$2;
            final existingRatio = result.requiredAmount == 0
                ? 0.0
                : (result.existingCoverage / result.requiredAmount)
                    .clamp(0.0, 1.0);
            final existing = required * existingRatio;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: required,
                  width: 18,
                  color: categories[index].$3,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: required,
                    color: categories[index].$3.withValues(alpha: 0.15),
                  ),
                ),
                BarChartRodData(
                  toY: existing,
                  width: 10,
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class BreakdownCard extends StatelessWidget {
  const BreakdownCard({
    super.key,
    required this.result,
    this.input,
  });

  final DiagnosisResult result;
  final DiagnosisInput? input;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pre65Living = input != null
        ? calcPreRetirementLivingExpense(input!)
        : null;
    final post65Living = input != null
        ? calcRetirementLivingExpense(input!)
        : null;
    final retirementSummary = input != null && input!.hasSpouse
        ? RetirementGuaranteeSummary.from(input: input!, result: result)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('費目別の詳細',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '保障が必要な額（費目別）',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _row('👨‍👩‍👧 生活費不足分', result.livingExpense, bold: true),
            if (pre65Living != null && post65Living != null) ...[
              _subRow('65歳まで', pre65Living),
              _subRow('65歳以降（公的年金控除後）', post65Living),
              if (retirementSummary != null &&
                  retirementSummary.livingShortfallTotalMan > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2, bottom: 6),
                  child: Text(
                    '65歳以降：${formatYen(retirementSummary.monthlyShortfallYen)}/月'
                    ' × 12 × ${retirementSummary.retirementYears}年'
                    ' ＝ ${formatManYen(retirementSummary.livingShortfallTotalMan)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ),
            ],
            _row('🎓 教育費', result.educationFee),
            _row('🏠 住居費', result.housingFee),
            _row('⚰️ 葬儀等', result.funeralFee),
            const Divider(height: 28),
            _row('合計（必要額）', result.requiredAmount, bold: true),
            const SizedBox(height: 12),
            Text(
              '足りる分',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.secondary,
                  ),
            ),
            const SizedBox(height: 8),
            _row(
              '💳 既存保障',
              result.existingCoverage,
              kind: _BreakdownKind.credit,
            ),
            const SizedBox(height: 8),
            Text(
              '※ 公的年金・配偶者就労は生活費に反映済み。'
              '詳細は下の「計算の考え方」をご覧ください。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.outline,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '不足額 ＝ 合計 − 既存保障',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.outline,
                  ),
            ),
            const Divider(height: 28),
            _row(
              '不足額',
              result.gap,
              bold: true,
              kind: _BreakdownKind.result,
              color: result.gap > 0 ? AppColors.error : AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    int amount, {
    bool bold = false,
    Color? color,
    _BreakdownKind kind = _BreakdownKind.expense,
  }) {
    final displayColor = color ??
        (kind == _BreakdownKind.credit ? AppColors.secondary : null);
    final formatted = switch (kind) {
      _BreakdownKind.credit =>
        amount == 0 ? formatManYen(0) : '+${formatManYen(amount)}',
      _BreakdownKind.result => formatManYen(amount),
      _BreakdownKind.expense => formatManYen(amount),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(
            formatted,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: displayColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _subRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 2, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.outline),
          ),
          Text(
            formatManYen(amount),
            style: const TextStyle(fontSize: 13, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

enum _BreakdownKind { expense, credit, result }

class SummaryHeroCard extends StatelessWidget {
  const SummaryHeroCard({super.key, required this.result});

  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    final isShortfall = result.gap > 0;
    return Card(
      color: isShortfall
          ? AppColors.error.withValues(alpha: 0.08)
          : AppColors.secondary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isShortfall ? '不足額' : '過剰保障',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            CountUpText(
              value: result.gap,
              formatter: formatGap,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: isShortfall ? AppColors.error : AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isShortfall
                  ? '定期保険でカバーできます'
                  : '保険料の見直し余地があります',
            ),
          ],
        ),
      ),
    );
  }
}
