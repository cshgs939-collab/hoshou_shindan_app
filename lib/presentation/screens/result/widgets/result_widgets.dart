import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatter.dart';
import '../../../../data/models/diagnosis_result.dart';
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
  const BreakdownCard({super.key, required this.result});

  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('費目別の詳細',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _row('👨‍👩‍👧 遺族生活費', result.livingExpense),
            _row('🎓 教育費', result.educationFee),
            _row('🏠 住居費', result.housingFee),
            _row('⚰️ 葬儀等', result.funeralFee),
            const Divider(height: 28),
            _row('合計', result.requiredAmount, bold: true),
            const SizedBox(height: 8),
            _row('💰 遺族年金', -result.survivorPension),
            _row('💳 既存保障', -result.existingCoverage),
            const Divider(height: 28),
            _row(
              '不足額',
              result.gap,
              bold: true,
              color: result.gap > 0 ? AppColors.error : AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int amount,
      {bool bold = false, Color? color}) {
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
            amount < 0
                ? '-${formatManYen(amount.abs())}'
                : formatManYen(amount),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

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
