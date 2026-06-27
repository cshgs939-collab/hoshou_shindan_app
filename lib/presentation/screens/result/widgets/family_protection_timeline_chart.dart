import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../domain/calculation/family_protection_timeline.dart';

class FamilyProtectionTimelineChart extends StatelessWidget {
  const FamilyProtectionTimelineChart({
    super.key,
    required this.timeline,
  });

  final FamilyProtectionTimeline timeline;

  @override
  Widget build(BuildContext context) {
    if (timeline.spans.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('表示できるタイムラインがありません')),
      );
    }

    final theme = Theme.of(context);
    final spanYears = timeline.timelineSpanYears;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AgeAxis(
          startAge: timeline.insuredAge,
          endAge: timeline.timelineEndAge,
        ),
        const SizedBox(height: 12),
        ...timeline.spans.map(
          (span) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TimelineRow(
              theme: theme,
              label: span.label,
              startAge: timeline.insuredAge,
              spanStart: span.startInsuredAge,
              spanEnd: span.endInsuredAge,
              totalYears: spanYears,
              color: Color(span.colorValue),
            ),
          ),
        ),
        if (timeline.children.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: timeline.children
                .map(
                  (child) => Text(
                    '${child.childNumber}人目：${child.currentAge}歳→'
                    '${child.graduationAge}歳（あなた${child.insuredAgeWhenGraduates}歳時）',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                )
                .toList(),
          ),
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

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.theme,
    required this.label,
    required this.startAge,
    required this.spanStart,
    required this.spanEnd,
    required this.totalYears,
    required this.color,
  });

  final ThemeData theme;
  final String label;
  final int startAge;
  final int spanStart;
  final int spanEnd;
  final int totalYears;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final left = (spanStart - startAge) / totalYears;
    final width = (spanEnd - spanStart) / totalYears;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth * width.clamp(0.05, 1.0);
            final barLeft = constraints.maxWidth * left.clamp(0.0, 0.95);
            return SizedBox(
              height: 14,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.outline.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Positioned(
                    left: barLeft,
                    width: barWidth,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
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
