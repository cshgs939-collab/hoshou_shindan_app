import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${currentStep + 1} / $totalSteps'),
            Text('${(progress * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.outline.withValues(alpha: 0.3),
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class AgeSliderField extends StatelessWidget {
  const AgeSliderField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 20,
    this.max = 79,
    this.valueSuffix = '歳',
    this.helper,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String valueSuffix;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.outline,
                ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(
                '$value$valueSuffix',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Slider(
                key: Key('${label}_slider'),
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                label: '$value$valueSuffix',
                onChanged: (v) => onChanged(v.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$min$valueSuffix'),
                  Text('$max$valueSuffix'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
