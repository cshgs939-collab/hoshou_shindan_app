import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatter.dart';
import '../../../../domain/calculation/coverage_timeline.dart';

class CoverageTimelineChart extends StatelessWidget {
  const CoverageTimelineChart({
    super.key,
    required this.points,
  });

  final List<CoverageTimelinePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('表示できるデータがありません')),
      );
    }

    final maxY = points
        .map((point) => max(point.requiredAmount, point.existingCoverage))
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final point = points[group.x];
                final label = rodIndex == 0 ? '必要' : '既存';
                final value = rod.toY.round();
                return BarTooltipItem(
                  '${point.age}歳 $label\n${formatManYen(value)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${value.round()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${points[index].age}歳',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(points.length, (index) {
            final point = points[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: point.requiredAmount.toDouble(),
                  width: 14,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: point.existingCoverage.toDouble(),
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

class CoverageGapLineChart extends StatelessWidget {
  const CoverageGapLineChart({
    super.key,
    required this.points,
  });

  final List<CoverageTimelinePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();

    final spots = points
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.gap.toDouble()))
        .toList();
    final maxGap = points.map((point) => point.gap.abs()).reduce(max).toDouble();

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          minY: min(0, spots.map((spot) => spot.y).reduce(min)),
          maxY: maxGap * 1.2,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.error,
              barWidth: 2,
              dotData: FlDotData(
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.error,
                    strokeWidth: 0,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
