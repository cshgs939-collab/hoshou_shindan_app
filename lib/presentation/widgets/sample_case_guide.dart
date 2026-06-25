import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// 初めての方向け・入力例（田中さん一家の例題）
class SampleCaseGuide {
  static const title = '例題：田中さん一家';

  static const intro =
      '数字の調べ方がわからなくても、この例題なら入力せず「次へ」だけで結果まで進められます。';

  static const rows = <({String item, String value, String how})>[
    (item: 'あなたの年齢', value: '35歳', how: 'そのまま'),
    (
      item: 'あなたの就業',
      value: '正社員・会社員',
      how: 'パート/自営/無職も選択可',
    ),
    (
      item: '配偶者・お子さん',
      value: 'あり / 33歳 / 1人(3歳)',
      how: 'そのまま',
    ),
    (item: 'あなたの年収', value: '500万円', how: '源泉徴収票の「支払金額」'),
    (item: '配偶者の年収', value: '200万円', how: 'パート収入の年間合計'),
    (
      item: '月間の生活費',
      value: '20万円',
      how: '食費等（家賃10万は別入力）',
    ),
    (item: '住居', value: '賃貸・家賃10万円', how: '毎月の家賃'),
    (item: '保険・貯金', value: '0円', how: 'わからなければ0でOK'),
    (
      item: '老後の生活費',
      value: '20万円/月',
      how: '65歳以降（公的年金のみ差引・就労は見込まない）',
    ),
  ];

  static const operationSteps = [
    '下の「例題で診断する」を押す',
    'ステップ1〜3 は数字を変えず「次へ」',
    '「計算する」→ 不足額の結果が表示されます',
  ];

  static const formulaLines = [
    '生活費不足分 ＝（必要月額 − 遺族年金 − 配偶者就労）× 年数（65歳まで）',
    '65歳以降 ＝（必要月額 − 公的年金）× 年数 ※就労は見込まない',
    '例：20万−11万＝9万/月 × 約22年 → 老後生活費で約2,376万円の保障',
    '不足額 ＝ 生活費不足分 ＋ 教育費 ＋ 住居費 ＋ 300万 − 既存保障',
    '結果画面の「計算の考え方」にあなたの試算根拠が表示されます',
  ];
}

class SampleCaseGuidePanel extends StatelessWidget {
  const SampleCaseGuidePanel({super.key, this.showTitle = false});

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: AppColors.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle)
              Text(
                SampleCaseGuide.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                '📘 ${SampleCaseGuide.title}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            Text(SampleCaseGuide.intro),
            const SizedBox(height: 16),
            Text('入力する数字', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...SampleCaseGuide.rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.item,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.value,
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.how,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Text('操作手順', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...SampleCaseGuide.operationSteps.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${e.key + 1}. ${e.value}'),
                  ),
                ),
            const SizedBox(height: 12),
            Text('結果の見方', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...SampleCaseGuide.formulaLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line, style: theme.textTheme.bodySmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
