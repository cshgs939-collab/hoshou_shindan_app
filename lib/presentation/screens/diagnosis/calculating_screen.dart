import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../widgets/animated_widgets.dart';
import '../../providers/diagnosis_input_provider.dart';
import '../../providers/history_provider.dart';

class CalculatingScreen extends ConsumerStatefulWidget {
  const CalculatingScreen({super.key});

  @override
  ConsumerState<CalculatingScreen> createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends ConsumerState<CalculatingScreen> {
  final _steps = [
    '遺族生活費を計算中',
    '教育費を計算中',
    '住居費を計算中',
    '遺族年金を計算中',
    '不足額を算出中',
  ];
  int _completed = 0;

  @override
  void initState() {
    super.initState();
    _runCalculation();
  }

  Future<void> _runCalculation() async {
    for (var i = 0; i < _steps.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() => _completed = i + 1);
    }

    final input = ref.read(diagnosisInputProvider);
    final result = await ref
        .read(diagnosisHistoryProvider.notifier)
        .saveCurrentDiagnosis(input);

    if (!mounted) return;
    context.go('/result/${result.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ShieldLoadingAnimation(),
              const SizedBox(height: 24),
              Text('計算中...', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              ...List.generate(_steps.length, (index) {
                final done = index < _completed;
                final current = index == _completed;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        done
                            ? Icons.check_circle
                            : current
                                ? Icons.hourglass_top
                                : Icons.circle_outlined,
                        color: done ? AppColors.secondary : AppColors.outline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_steps[index])),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
