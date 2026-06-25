import 'package:flutter/material.dart';

import '../../../core/utils/app_restart.dart';
import '../../../data/repositories/hive_encryption.dart';

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key, required this.error});

  final Object error;

  Future<void> _resetAndRestart(BuildContext context) async {
    await clearAllHiveStorage(HiveEncryption());
    await restartApp();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '起動エラー',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('アプリの初期化に失敗しました。'),
                const SizedBox(height: 8),
                const Text(
                  '以前の保存データとの互換性の問題の可能性があります。'
                  '下のボタンでデータを消去して再起動できます（診断履歴は失われます）。',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText('$error'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _resetAndRestart(context),
                    child: const Text('データを消去して再起動'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
