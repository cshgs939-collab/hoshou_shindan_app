import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_explanations.dart';
import '../../core/constants/pension_constants.dart';
import '../../core/enums/housing_type.dart';
import '../../core/utils/formatter.dart';
import '../../domain/calculation/calculation_engine.dart';
import '../../domain/calculation/coverage_timeline.dart';
import '../../domain/calculation/old_age_pension_calculator.dart';
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
    final advice = buildAdviceText(input, result);
    final timelinePoints = calcCoverageTimeline(input);
    final timelineGapAdvice = buildTimelineGapAdvice(timelinePoints);
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
                _oldAgePensionSection(font, input),
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
                pw.SizedBox(height: 16),
                _guideSection(font, input),
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
                  '保障額の推移',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('現在（${input.age}歳）〜 65歳まで'),
                pw.SizedBox(height: 4),
                pw.Text(
                  AppExplanations.coverageTimelineLead(input.age),
                  style: pw.TextStyle(font: font, fontSize: 9),
                ),
                pw.SizedBox(height: 4),
                ...AppExplanations.coverageTimelineBullets().map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      '・$line',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '単位: 万円　※ 既存保障は生保＋定期保険の合計',
                  style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
                ),
                pw.Divider(),
                pw.SizedBox(height: 8),
                _timelineTable(font, timelinePoints),
                if (timelineGapAdvice != null) ...[
                  pw.SizedBox(height: 16),
                  _noteBox(
                    font,
                    title: 'ご注意',
                    body: timelineGapAdvice,
                    background: PdfColors.red50,
                  ),
                ],
                pw.SizedBox(height: 16),
                _noteBox(
                  font,
                  title: '65歳以降は…',
                  body: post65MedicalAdvice,
                  background: PdfColors.blue50,
                ),
                pw.Spacer(),
                pw.Text(
                  '※ 各年齢時点での試算です。子どもの成長・ローン残債の減少・'
                  '定期保険満了を反映した概算です。',
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
    pw.TableRow row(
      String label,
      int amount, {
      bool bold = false,
      bool credit = false,
    }) {
      final text = credit
          ? (amount == 0 ? formatManYen(0) : '+${formatManYen(amount)}')
          : formatManYen(amount);
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
                text,
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
        row('生活費不足分', result.livingExpense),
        row('教育費', result.educationFee),
        row('住居費', result.housingFee),
        row('葬儀等', result.funeralFee),
        row('合計（必要額）', result.requiredAmount, bold: true),
        row('既存保障', result.existingCoverage, credit: true),
        row('不足額', result.gap, bold: true),
      ],
    );
  }

  pw.Widget _timelineTable(pw.Font font, List<CoverageTimelinePoint> points) {
    pw.Widget headerCell(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    pw.Widget dataCell(String text, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              font: font,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            headerCell('年齢'),
            headerCell('必要保障額'),
            headerCell('既存保障'),
            headerCell('不足額'),
          ],
        ),
        ...points.map(
          (point) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: pw.Text('${point.age}歳', style: pw.TextStyle(font: font)),
              ),
              dataCell(formatManYen(point.requiredAmount)),
              dataCell(formatManYen(point.existingCoverage)),
              dataCell(formatGap(point.gap), bold: true),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _noteBox(
    pw.Font font, {
    required String title,
    required String body,
    required PdfColor background,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(body, style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _guideSection(pw.Font font, DiagnosisInput input) {
    final lines = AppExplanations.pdfGuideLines(input);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '試算の考え方',
          style: pw.TextStyle(
            font: font,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        ...lines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              line,
              style: pw.TextStyle(font: font, fontSize: 9),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _oldAgePensionSection(pw.Font font, DiagnosisInput input) {
    final insured = estimateInsuredOldAgePension(input);
    final spouse = estimateSpouseOldAgePension(input);
    final gap = calcRetirementPensionGap(input);
    final lines = <String>[
      formatOldAgePensionSummary(insured),
      if (spouse != null) formatOldAgePensionSummary(spouse),
      AppExplanations.retirementGapExplanation(gap),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '${retirementStartAge}歳からの公的年金（概算・健在前提）',
          style: pw.TextStyle(
            font: font,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          AppExplanations.oldAgePensionLead(input),
          style: pw.TextStyle(font: font, fontSize: 9),
        ),
        pw.SizedBox(height: 6),
        ...lines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text('• $line', style: pw.TextStyle(font: font, fontSize: 10)),
          ),
        ),
        pw.Text(
          '※ 万一の保障試算とは別の老後収入目安です。',
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
        ),
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
