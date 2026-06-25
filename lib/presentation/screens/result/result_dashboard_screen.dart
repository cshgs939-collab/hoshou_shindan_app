import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatter.dart';
import '../../../data/export/diagnosis_json_exporter.dart';
import '../../../data/models/diagnosis_input.dart';
import '../../../data/models/diagnosis_result.dart';
import '../../../data/repositories/hive_repository.dart';
import '../../../domain/calculation/calculation_engine.dart';
import '../../providers/diagnosis_input_provider.dart';
import '../../providers/export_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/primary_button.dart';
import 'widgets/result_widgets.dart';

class ResultDashboardScreen extends ConsumerWidget {
  const ResultDashboardScreen({super.key, required this.resultId});

  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(hiveRepositoryProvider);
    final result = repository.getResult(resultId);
    final input = result == null ? null : repository.getInput(result.inputId);

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('診断結果')),
        body: const Center(child: Text('診断結果が見つかりません')),
      );
    }

    final advice = buildAdviceText(result);

    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        actions: [
          if (input != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'PDFで共有',
              onPressed: () => _sharePdf(context, ref, input, result),
            ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SummaryHeroCard(result: result),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: '必要保障額',
                  value: formatManYen(result.requiredAmount),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: '既存保障合計',
                  value: formatManYen(result.existingCoverage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('必要 vs 既存',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  CoverageBarChart(result: result),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          BreakdownCard(result: result),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 アドバイス',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(advice),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: '再診断する',
            onPressed: () {
              ref.read(diagnosisInputProvider.notifier).reset();
              context.push('/diagnosis/step1');
            },
          ),
          const SizedBox(height: 12),
          if (result.childrenCount > 0)
            OutlinedButton(
              onPressed: () => context.push('/scenario?resultId=$resultId'),
              child: const Text('教育方針シナリオ比較'),
            ),
          if (result.childrenCount > 0) const SizedBox(height: 12),
          OutlinedButton(
            onPressed: input == null
                ? null
                : () => _sharePdf(context, ref, input, result),
            child: const Text('PDFで保存・共有'),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(diagnosisHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('診断履歴')),
      floatingActionButton: history.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/compare'),
              icon: const Icon(Icons.compare_arrows),
              label: const Text('比較'),
            )
          : null,
      body: history.isEmpty
          ? const Center(child: Text('診断履歴がありません'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => ref
                      .read(diagnosisHistoryProvider.notifier)
                      .deleteResult(item.id),
                  child: ListTile(
                    title: Text(formatDate(item.calculatedAt)),
                    subtitle: Text(
                      '必要${formatManYen(item.requiredAmount)} / '
                      '既存${formatManYen(item.existingCoverage)}',
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
                );
              },
            ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const ListTile(title: Text('表示設定')),
          SwitchListTile(
            title: const Text('ダークモード'),
            value: settings.isDarkMode,
            onChanged: notifier.setDarkMode,
          ),
          ListTile(
            title: const Text('フォントサイズ'),
            subtitle: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('小')),
                ButtonSegment(value: 1, label: Text('中')),
                ButtonSegment(value: 2, label: Text('大')),
              ],
              selected: {settings.fontSize},
              onSelectionChanged: (value) =>
                  notifier.setFontSize(value.first),
            ),
          ),
          const Divider(),
          if (!kIsWeb) ...[
            const ListTile(title: Text('通知設定')),
            SwitchListTile(
              title: const Text('年次リマインダー'),
              value: settings.notificationEnabled,
              onChanged: notifier.setNotificationEnabled,
            ),
            ListTile(
              title: const Text('通知タイミング'),
              subtitle: Text('毎年${settings.notificationMonth}月'),
              trailing: DropdownButton<int>(
                value: settings.notificationMonth,
                items: List.generate(
                  12,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}月'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) notifier.setNotificationMonth(value);
                },
              ),
            ),
            const Divider(),
          ] else
            const ListTile(
              title: Text('Web版について'),
              subtitle: Text(
                'ブラウザ版では通知・ホーム画面ウィジェットは利用できません。'
                'データは端末内（ブラウザ）に保存されます。',
              ),
            ),
          if (!kIsWeb) const Divider(),
          const ListTile(title: Text('データ管理')),
          ListTile(
            title: const Text('データをエクスポート（JSON）'),
            subtitle: const Text('診断履歴を共有'),
            onTap: () async {
              try {
                await ref.read(jsonExporterProvider).shareAllHistory();
              } on ExportException catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message)),
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('エクスポートに失敗しました: $error')),
                );
              }
            },
          ),
          ListTile(
            title: const Text('教育方針シナリオ比較'),
            subtitle: const Text('公立・私立などの不足額差を確認'),
            onTap: () => context.push('/scenario'),
          ),
          ListTile(
            title: const Text('診断履歴を比較'),
            subtitle: const Text('2件の診断結果を並べて確認'),
            onTap: () => context.push('/compare'),
          ),
          ListTile(
            title: const Text('ホーム画面ウィジェット'),
            subtitle: Text(
              kIsWeb
                  ? 'Web版では利用できません（iOS/Android アプリ専用）'
                  : 'iOS / Android のホーム画面に不足額を表示（診断後に自動更新）',
            ),
          ),
          ListTile(
            title: const Text('診断履歴を全削除'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('履歴を削除しますか？'),
                  content: const Text('保存済みの診断履歴がすべて削除されます。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('削除'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(diagnosisHistoryProvider.notifier)
                    .clearAll();
              }
            },
          ),
          const Divider(),
          const ListTile(
            title: Text('アプリ情報'),
            subtitle: Text('バージョン v1.0.0'),
          ),
          ListTile(
            title: const Text('免責事項'),
            onTap: () => _showTextDialog(
              context,
              '免責事項',
              '本アプリの試算結果は概算であり、実際の必要保障額を保証するものではありません。'
              '保険商品のご加入にあたっては、専門家へのご相談をおすすめします。',
            ),
          ),
          ListTile(
            title: const Text('プライバシーポリシー'),
            onTap: () => _showTextDialog(
              context,
              'プライバシーポリシー',
              '入力データは端末内にのみ保存され、外部サーバーへ送信されません。'
              '広告配信や第三者へのデータ販売は行いません。'
              '診断履歴は AES 暗号化で端末内に保存されます。'
              'アプリをアンインストールするとデータは削除されます。'
              '詳細: docs/PRIVACY_POLICY.md（GitHub 公開）',
            ),
          ),
        ],
      ),
    );
  }

  void _showTextDialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
