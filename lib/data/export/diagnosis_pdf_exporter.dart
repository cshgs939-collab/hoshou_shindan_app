import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/enums/housing_type.dart';
import '../../core/utils/formatter.dart';
import '../../domain/calculation/calculation_engine.dart';
import '../models/diagnosis_input.dart';
import '../models/diagnosis_result.dart';

class DiagnosisPdfExporter {
  pw.Font? _font;

  Future<pw.Font> _loadFont() async {
    if (_font != null) return _font!;
    final data =
        await rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf');
    _font = pw.Font.ttf(data);
    return _font!;
  }

  Future<void> share({
    required DiagnosisInput input,
    required DiagnosisResult result,
  }) async {
    final bytes = await buildPdf(input: input, result: result);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'mamoru_keisan_${result.calculatedAt.millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> preview({
    required DiagnosisInput input,
    required DiagnosisResult result,
  }) async {
    final bytes = await buildPdf(input: input, result: result);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<Uint8List> buildPdf({
    required DiagnosisInput input,
    required DiagnosisResult result,
  }) async {
    final font = await _loadFont();
    final advice = buildAdviceText(result);
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.DefaultTextStyle(
            style: pw.TextStyle(font: font, fontSize: 11),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'まもる計算 診断結果',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('診断日: ${formatDate(result.calculatedAt)}'),
                pw.Divider(),
                pw.SizedBox(height: 8),
                _heroSection(font, result),
                pw.SizedBox(height: 16),
                _summaryRow(font, result),
                pw.SizedBox(height: 16),
                pw.Text(
                  '費目別内訳',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                _breakdownTable(font, result),
                pw.SizedBox(height: 16),
                pw.Text(
                  '入力サマリー',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                _inputSummary(font, input),
                pw.Spacer(),
                pw.Text(
                  'アドバイス',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(advice, style: pw.TextStyle(font: font, fontSize: 10)),
                pw.SizedBox(height: 12),
                pw.Text(
                  '※ 本書は概算試算結果です。実際の必要保障額を保証するものではありません。',
                  style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  pw.Widget _heroSection(pw.Font font, DiagnosisResult result) {
    final label = result.gap > 0 ? '不足額' : '過剰保障';
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 12)),
          pw.Text(
            formatGap(result.gap),
            style: pw.TextStyle(
              font: font,
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(pw.Font font, DiagnosisResult result) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _metricBox(font, '必要保障額', formatManYen(result.requiredAmount)),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child:
              _metricBox(font, '既存保障合計', formatManYen(result.existingCoverage)),
        ),
      ],
    );
  }

  pw.Widget _metricBox(pw.Font font, String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _breakdownTable(pw.Font font, DiagnosisResult result) {
    pw.TableRow row(String label, int amount, {bool bold = false}) {
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                amount < 0
                    ? '-${formatManYen(amount.abs())}'
                    : formatManYen(amount),
                style: pw.TextStyle(
                  font: font,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: pw.BorderSide(color: PdfColors.grey300),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        row('遺族生活費', result.livingExpense),
        row('教育費', result.educationFee),
        row('住居費', result.housingFee),
        row('葬儀等', result.funeralFee),
        row('合計', result.requiredAmount, bold: true),
        row('遺族年金', -result.survivorPension),
        row('既存保障', -result.existingCoverage),
        row('不足額', result.gap, bold: true),
      ],
    );
  }

  pw.Widget _inputSummary(pw.Font font, DiagnosisInput input) {
    final lines = <String>[
      '被保険者: ${input.age}歳',
      if (input.hasSpouse) '配偶者: ${input.spouseAge ?? '-'}歳',
      '子ども: ${input.childrenAges.length}人'
          '${input.childrenAges.isEmpty ? '' : ' (${input.childrenAges.join('歳, ')}歳)'}',
      '年収: ${formatManYen(input.annualIncome)}',
      '月間生活費: ${input.monthlyExpense}万円/月',
      '住居: ${_housingLabel(input.residenceType)}',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines
          .map((line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• $line'),
              ))
          .toList(),
    );
  }

  String _housingLabel(HousingType type) {
    return switch (type) {
      HousingType.mortgaged => '持家（ローンあり）',
      HousingType.owned => '持家（完済）',
      HousingType.renting => '賃貸',
    };
  }
}
