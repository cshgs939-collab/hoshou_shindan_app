import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import '../models/diagnosis_input.dart';
import '../models/diagnosis_result.dart';
import '../repositories/hive_repository.dart';
import 'diagnosis_export.dart';

class DiagnosisJsonExporter {
  const DiagnosisJsonExporter(this._repository);

  final HiveRepository _repository;

  Future<void> shareAllHistory() async {
    final history = _repository.getHistory();
    if (history.isEmpty) {
      throw ExportException('エクスポートする診断履歴がありません');
    }

    final records = <Map<String, dynamic>>[];
    for (final result in history) {
      final input = _repository.getInput(result.inputId);
      if (input == null) continue;
      records.add(diagnosisRecordToJson(input: input, result: result));
    }

    final payload = {
      'app': 'まもる計算',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'records': records,
    };

    final json = const JsonEncoder.withIndent('  ').convert(payload);
    await Share.share(json, subject: 'まもる計算 診断データ');
  }

  Future<void> shareRecord({
    required DiagnosisInput input,
    required DiagnosisResult result,
  }) async {
    final json = const JsonEncoder.withIndent('  ').convert(
      diagnosisRecordToJson(input: input, result: result),
    );
    await Share.share(json, subject: 'まもる計算 診断結果');
  }
}

class ExportException implements Exception {
  ExportException(this.message);
  final String message;

  @override
  String toString() => message;
}
