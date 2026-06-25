import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatter.dart';
import '../../../data/models/diagnosis_input.dart';
import '../../../data/repositories/hive_repository.dart';
import '../../../domain/scenario/scenario_comparison.dart';
import '../../providers/diagnosis_input_provider.dart';
import '../../providers/history_provider.dart';

final scenarioComparisonProvider = Provider<ScenarioComparisonService>((ref) {
  return ScenarioComparisonService(ref.watch(calculationEngineProvider));
});

class ScenarioScreen extends ConsumerWidget {
  const ScenarioScreen({super.key, this.resultId});

  final String? resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(hiveRepositoryProvider);
    final baseInput = _resolveInput(ref, repository);
    if (baseInput == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('教育方針シナリオ比較')),
        body: const Center(child: Text('比較する診断データがありません')),
      );
    }

    if (baseInput.childrenAges.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('教育方針シナリオ比較')),
        body: const Center(child: Text('お子さんがいる場合に比較できます')),
      );
    }

    final scenarios =
        ref.read(scenarioComparisonProvider).compare(baseInput);
    final best = ref.read(scenarioComparisonProvider).lowestGapScenario(
          scenarios,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('教育方針シナリオ比較')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '同じ家族・収入条件のまま、教育方針だけを変えた場合の不足額を比較します。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (best != null)
            Card(
              color: AppColors.secondary.withValues(alpha: 0.08),
              child: ListTile(
                title: const Text('不足額が最も少ない方針'),
                subtitle: Text(best.label),
                trailing: Text(
                  formatGap(best.result.gap),
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          ...scenarios.map(
            (scenario) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _metricRow('教育費', formatManYen(scenario.result.educationFee)),
                    _metricRow('必要保障額', formatManYen(scenario.result.requiredAmount)),
                    _metricRow(
                      '不足額',
                      formatGap(scenario.result.gap),
                      emphasize: true,
                      color: scenario.result.gap > 0
                          ? AppColors.error
                          : AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DiagnosisInput? _resolveInput(WidgetRef ref, HiveRepository repository) {
    if (resultId != null) {
      final result = repository.getResult(resultId!);
      if (result == null) return null;
      return repository.getInput(result.inputId);
    }
    final draft = ref.watch(diagnosisInputProvider);
    if (draft.annualIncome > 0 && draft.monthlyExpense > 0) {
      return draft;
    }
    final latest = repository.getHistory().firstOrNull;
    if (latest == null) return null;
    return repository.getInput(latest.inputId);
  }

  Widget _metricRow(
    String label,
    String value, {
    bool emphasize = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
