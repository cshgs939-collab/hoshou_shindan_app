import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatter.dart';
import '../../providers/diagnosis_input_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/sample_case_guide.dart';
import '../guide/sample_guide_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestResultProvider);
    final history = ref.watch(diagnosisHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('まもる計算'),
        actions: [
          TextButton(
            onPressed: () => context.push('/sample-guide'),
            child: const Text('例題'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SampleCaseGuidePanel(),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () {
              ref.read(diagnosisInputProvider.notifier).loadSampleCase();
              ref.read(currentStepProvider.notifier).state = 0;
              ref.read(isSampleCaseModeProvider.notifier).state = true;
              context.push('/diagnosis/step1');
            },
            child: const Text('例題で診断する（そのまま次へ）'),
          ),
          const SizedBox(height: 24),
          if (latest != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('最新の診断結果',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(formatDate(latest.calculatedAt)),
                    const SizedBox(height: 16),
                    Text(
                      latest.gap > 0 ? '不足額' : '過剰保障',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      formatGap(latest.gap),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: latest.gap > 0
                                ? AppColors.error
                                : AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.push('/result/${latest.id}'),
                      child: const Text('詳細を見る →'),
                    ),
                    if (latest.childrenCount > 0) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.push(
                          '/scenario?resultId=${latest.id}',
                        ),
                        child: const Text('教育方針シナリオ比較'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🆕 自分の数字で診断する',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('家族の状況に合わせて入力してください'),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: '診断スタート →',
                    onPressed: () {
                      ref.read(diagnosisInputProvider.notifier).reset();
                      ref.read(currentStepProvider.notifier).state = 0;
                      ref.read(isSampleCaseModeProvider.notifier).state = false;
                      context.push('/diagnosis/step1');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📋 診断履歴（${history.length}件）',
                  style: Theme.of(context).textTheme.titleMedium),
              if (history.isNotEmpty)
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: const Text('すべて見る'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('まだ診断履歴がありません。上の例題から試してみましょう。'),
              ),
            )
          else
            ...history.take(3).map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(formatDate(item.calculatedAt)),
                      subtitle: Text(
                        '子ども${item.childrenCount}人'
                        '${item.hasSpouse ? '・配偶者あり' : ''}',
                      ),
                      trailing: Text(
                        formatGap(item.gap),
                        style: TextStyle(
                          color: item.gap > 0
                              ? AppColors.error
                              : AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => context.push('/result/${item.id}'),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
