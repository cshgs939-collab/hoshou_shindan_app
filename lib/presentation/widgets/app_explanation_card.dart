import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// 説明文（リード＋箇条書き）を表示する共通カード
class AppExplanationCard extends StatelessWidget {
  const AppExplanationCard({
    super.key,
    required this.title,
    required this.lead,
    this.bullets = const [],
    this.tint = AppColors.primary,
  });

  final String title;
  final String lead;
  final List<String> bullets;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: tint.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: tint,
              ),
            ),
            const SizedBox(height: 8),
            Text(lead, style: theme.textTheme.bodySmall),
            if (bullets.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...bullets.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '・$line',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
