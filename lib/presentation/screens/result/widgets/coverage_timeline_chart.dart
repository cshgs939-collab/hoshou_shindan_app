import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatter.dart';
import '../../../../domain/calculation/coverage_timeline.dart';

/// 「1,000万円・35歳〜60歳」形式の区間グラフ
class CoveragePeriodTimelineChart extends StatelessWidget {
  const CoveragePeriodTimelineChart({
    super.key,
    required this.data,
    this.compact = false,
  });

  final CoveragePeriodChartData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (data.rows.isEmpty) {
      return SizedBox(
        height: compact ? 120 : 200,
        child: const Center(child: Text('表示できる保障データがありません')),
      );
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AgeAxis(startAge: data.startAge, endAge: data.endAge),
        const SizedBox(height: 12),
        ...data.rows.map(
          (row) => Padding(
            padding: EdgeInsets.only(bottom: compact ? 10 : 14),
            child: _PeriodRow(
              theme: theme,
              title: row.title,
              segments: row.segments,
              startAge: data.startAge,
              totalYears: data.spanYears,
              compact: compact,
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          _SummaryList(lines: data.summaryLines, theme: theme),
        ],
      ],
    );
  }
}

class _AgeAxis extends StatelessWidget {
  const _AgeAxis({required this.startAge, required this.endAge});

  final int startAge;
  final int endAge;

  @override
  Widget build(BuildContext context) {
    final mid = startAge + ((endAge - startAge) / 2).round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('あなた${startAge}歳', style: const TextStyle(fontSize: 11)),
        Text('${mid}歳', style: const TextStyle(fontSize: 11)),
        Text('${endAge}歳', style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({
    required this.theme,
    required this.title,
    required this.segments,
    required this.startAge,
    required this.totalYears,
    required this.compact,
  });

  final ThemeData theme;
  final String title;
  final List<CoveragePeriodSegment> segments;
  final int startAge;
  final int totalYears;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 11 : 12,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            return SizedBox(
              height: compact ? 36 : 44,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.outline.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  ...segments.map(
                    (seg) => _SegmentBar(
                      segment: seg,
                      startAge: startAge,
                      totalYears: totalYears,
                      trackWidth: trackWidth,
                      compact: compact,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.segment,
    required this.startAge,
    required this.totalYears,
    required this.trackWidth,
    required this.compact,
  });

  final CoveragePeriodSegment segment;
  final int startAge;
  final int totalYears;
  final double trackWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final left = (segment.startAge - startAge) / totalYears;
    final width = max(0.08, (segment.endAge - segment.startAge) / totalYears);
    final barLeft = trackWidth * left.clamp(0.0, 0.92);
    final barWidth = trackWidth * width.clamp(0.08, 1.0 - left);

    return Positioned(
      left: barLeft,
      width: barWidth,
      top: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Color(segment.colorValue),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatManYen(segment.amountMan),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              Text(
                segment.ageRangeLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: compact ? 8 : 9,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.lines, required this.theme});

  final List<String> lines;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '保障の一覧',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('・', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(line, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 後方互換（結果画面の凡例）
class CoverageStackedLegend extends StatelessWidget {
  const CoverageStackedLegend({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      '各バーに金額と年齢区間を表示しています',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.outline,
            fontSize: compact ? 10 : 11,
          ),
    );
  }
}
