import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// ステップ3：既存保障の3種類の違い
class ExistingInsuranceGuide extends StatelessWidget {
  const ExistingInsuranceGuide({super.key});

  static const rows = <({String name, String payout, String input})>[
    (
      name: '終身・養老など（一時金）',
      payout: '死亡時にまとまって受取',
      input: '証券の「死亡保険金」を万円で入力',
    ),
    (
      name: '定期保険（一時金）',
      payout: '契約期間内の死亡でまとまって受取',
      input: '死亡保険金（万円）と保障終了年齢を入力',
    ),
    (
      name: '収入保障保険（分割受取）',
      payout: '死亡後、毎月一定額を年数分',
      input: '月額（万円/月）と受取年数を入力',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: AppColors.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📘 3種類の保険の違い',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'どれも「世帯主が亡くなったとき」の保障です。'
              '受け取り方が違うだけで、アプリでは合計して「既存保障」に加算します。',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '受取：${row.payout}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '入力：${row.input}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
