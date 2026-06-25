import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatter.dart';
import '../../../data/models/diagnosis_result.dart';
import '../../providers/history_provider.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  DiagnosisResult? _left;
  DiagnosisResult? _right;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(diagnosisHistoryProvider);

    if (history.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('診断比較')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('比較するには診断履歴が2件以上必要です。'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('診断比較')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PickerCard(
            label: '比較元',
            selected: _left,
            history: history,
            onChanged: (value) => setState(() => _left = value),
          ),
          const SizedBox(height: 12),
          _PickerCard(
            label: '比較先',
            selected: _right,
            history: history,
            onChanged: (value) => setState(() => _right = value),
          ),
          if (_left != null && _right != null) ...[
            const SizedBox(height: 24),
            _CompareSummary(left: _left!, right: _right!),
            const SizedBox(height: 16),
            _CompareTable(left: _left!, right: _right!),
          ],
        ],
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.label,
    required this.selected,
    required this.history,
    required this.onChanged,
  });

  final String label;
  final DiagnosisResult? selected;
  final List<DiagnosisResult> history;
  final ValueChanged<DiagnosisResult?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<DiagnosisResult>(
              initialValue: selected,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '診断を選択',
              ),
              items: history
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        '${formatDate(item.calculatedAt)} (${formatGap(item.gap)})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareSummary extends StatelessWidget {
  const _CompareSummary({required this.left, required this.right});

  final DiagnosisResult left;
  final DiagnosisResult right;

  @override
  Widget build(BuildContext context) {
    final gapDelta = right.gap - left.gap;
    final improved = gapDelta < 0;
    return Card(
      color: improved
          ? AppColors.secondary.withValues(alpha: 0.08)
          : AppColors.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('不足額の変化',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              gapDelta == 0
                  ? '変化なし'
                  : '${gapDelta > 0 ? '+' : ''}${formatManYen(gapDelta)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: improved ? AppColors.secondary : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              improved
                  ? '比較先の方が不足額が少なくなっています。'
                  : gapDelta == 0
                      ? '2件の診断で不足額に差はありません。'
                      : '比較先の方が不足額が増えています。',
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.left, required this.right});

  final DiagnosisResult left;
  final DiagnosisResult right;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _compareRow(context, '不足額', left.gap, right.gap),
            _compareRow(context, '必要保障額', left.requiredAmount, right.requiredAmount),
            _compareRow(context, '既存保障', left.existingCoverage, right.existingCoverage),
            _compareRow(context, '遺族生活費', left.livingExpense, right.livingExpense),
            _compareRow(context, '教育費', left.educationFee, right.educationFee),
            _compareRow(context, '住居費', left.housingFee, right.housingFee),
          ],
        ),
      ),
    );
  }

  Widget _compareRow(
    BuildContext context,
    String label,
    int leftValue,
    int rightValue,
  ) {
    final delta = rightValue - leftValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            child: Text(formatManYen(leftValue), textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text(formatManYen(rightValue), textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text(
              delta == 0
                  ? '±0'
                  : '${delta > 0 ? '+' : ''}${formatManYen(delta)}',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: delta == 0
                    ? null
                    : delta < 0
                        ? AppColors.secondary
                        : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
