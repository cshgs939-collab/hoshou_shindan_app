import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_explanations.dart';
import '../../../data/models/diagnosis_input.dart';
import '../../../data/models/diagnosis_result.dart';
import '../../../data/repositories/hive_repository.dart';
import '../../../domain/calculation/coverage_timeline.dart';
import '../../providers/export_provider.dart';
import '../../widgets/app_explanation_card.dart';
import '../../widgets/primary_button.dart';
import 'widgets/coverage_timeline_chart.dart';

class CoverageTimelineScreen extends ConsumerWidget {
  const CoverageTimelineScreen({super.key, required this.resultId});

  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(hiveRepositoryProvider);
    final result = repository.getResult(resultId);
    final input = result == null ? null : repository.getInput(result.inputId);

    if (result == null || input == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('保障額の推移')),
        body: const Center(child: Text('診断結果が見つかりません')),
      );
    }

    final points = calcCoverageTimeline(input);
    final gapAdvice = buildTimelineGapAdvice(points);

    return Scaffold(
      appBar: AppBar(
        title: const Text('保障額の推移'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'PDFで共有',
            onPressed: () => _sharePdf(context, ref, input, result),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppExplanationCard(
            title: 'このグラフについて',
            lead: AppExplanations.coverageTimelineLead(input.age),
            bullets: AppExplanations.coverageTimelineBullets(),
          ),
          const SizedBox(height: 16),
          Text(
            '現在（${input.age}歳）〜 65歳まで',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '万円',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.outline,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CoverageTimelineChart(points: points),
                  const SizedBox(height: 12),
                  CoverageGapLineChart(points: points),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _LegendItem(color: AppColors.primary, label: '必要保障額'),
              _LegendItem(color: AppColors.secondary, label: '既存保障（生保＋定期）'),
              _LegendItem(color: AppColors.error, label: '不足額ライン'),
            ],
          ),
          if (gapAdvice != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.error.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(child: Text(gapAdvice)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '65歳以降は…',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(post65MedicalAdvice),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _sharePdf(context, ref, input, result),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDFで保存・共有'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: '診断結果に戻る',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(
    BuildContext context,
    WidgetRef ref,
    DiagnosisInput input,
    DiagnosisResult result,
  ) async {
    try {
      await ref.read(pdfExporterProvider).share(input: input, result: result);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDFの作成に失敗しました: $error')),
      );
    }
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
