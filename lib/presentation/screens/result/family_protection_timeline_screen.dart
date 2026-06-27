import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_explanations.dart';
import '../../../data/repositories/hive_repository.dart';
import '../../../domain/calculation/family_protection_timeline.dart';
import '../../../domain/calculation/insurance_period.dart';
import '../../widgets/app_explanation_card.dart';
import '../../widgets/primary_button.dart';
import 'widgets/family_protection_timeline_chart.dart';

class FamilyProtectionTimelineScreen extends ConsumerWidget {
  const FamilyProtectionTimelineScreen({super.key, required this.resultId});

  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(hiveRepositoryProvider);
    final result = repository.getResult(resultId);
    final input = result == null ? null : repository.getInput(result.inputId);

    if (result == null || input == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('保障期間と進路')),
        body: const Center(child: Text('診断結果が見つかりません')),
      );
    }

    final timeline = buildFamilyProtectionTimeline(input);
    final period = InsurancePeriodSummary.from(input);

    return Scaffold(
      appBar: AppBar(title: const Text('保障期間と進路')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppExplanationCard(
            title: '保障期間と進路グラフ',
            lead: AppExplanations.familyTimelineLead(input),
            bullets: AppExplanations.familyTimelineBullets(input),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FamilyProtectionTimelineChart(timeline: timeline),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _LegendItem(color: AppColors.secondary, label: '定期保険'),
              _LegendItem(color: AppColors.primary, label: '推奨保障期間'),
              _LegendItem(color: AppColors.education, label: 'お子さんの卒業'),
              _LegendItem(color: AppColors.education, label: '配偶者65歳'),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: period.termCoversRecommended
                ? AppColors.secondary.withValues(alpha: 0.08)
                : AppColors.error.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period.termCoversRecommended
                        ? '✓ 定期保険は推奨期間をカバー'
                        : '⚠ 定期保険が推奨期間より短い可能性',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: period.termCoversRecommended
                              ? AppColors.secondary
                              : AppColors.error,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '推奨：約${period.recommendedYears}年'
                    '${period.hasTermInsurancePeriod ? ' / 定期保険残り：${period.termRemainingYears}年（${period.termInsuranceEndAge}歳まで）' : ''}',
                  ),
                  if (period.termShortfallYears != null)
                    Text(
                      '不足：約${period.termShortfallYears}年',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!input.hasSpouse && input.childrenAges.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppExplanationCard(
              title: '進路別の卒業・自立年齢',
              lead: 'お子さんごとの進路設定により、保障が必要な期間が変わります。',
              bullets: AppExplanations.educationGraduationBullets(),
              tint: AppColors.primary,
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: '診断結果に戻る',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
