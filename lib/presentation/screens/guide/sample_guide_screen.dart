import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/diagnosis_input_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/sample_case_guide.dart';

/// 例題ガイド専用画面
class SampleGuideScreen extends ConsumerWidget {
  const SampleGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('例題ガイド')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SampleCaseGuidePanel(showTitle: true),
          const SizedBox(height: 24),
          PrimaryButton(
            label: '例題で診断する →',
            onPressed: () {
              ref.read(diagnosisInputProvider.notifier).loadSampleCase();
              ref.read(currentStepProvider.notifier).state = 0;
              ref.read(isSampleCaseModeProvider.notifier).state = true;
              context.go('/diagnosis/step1');
            },
          ),
        ],
      ),
    );
  }
}

/// 例題モード中は各ステップ上部に表示
class SampleModeBanner extends ConsumerWidget {
  const SampleModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSample = ref.watch(isSampleCaseModeProvider);
    if (!isSample) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Text(
        '📘 例題モード：数字はそのままで「次へ」を押すだけでOKです',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

final isSampleCaseModeProvider = StateProvider<bool>((ref) => false);
