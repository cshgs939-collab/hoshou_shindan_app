import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/utils/formatter.dart';
import '../../data/models/diagnosis_result.dart';

class WidgetService {
  static const androidWidgetName = 'MamoruHomeWidgetProvider';
  static const iOSWidgetName = 'MamoruHomeWidget';

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId('group.mamoru.keisan.widget');
    } catch (_) {
      // iOS以外では不要
    }
  }

  Future<void> updateFromResult(DiagnosisResult? result) async {
    if (kIsWeb) return;

    if (result == null) {
      await HomeWidget.saveWidgetData<String>('gap_label', '未診断');
      await HomeWidget.saveWidgetData<String>('gap_value', '-');
      await HomeWidget.saveWidgetData<String>('updated_at', '');
    } else {
      await HomeWidget.saveWidgetData<String>(
        'gap_label',
        result.gap > 0 ? '不足額' : '過剰保障',
      );
      await HomeWidget.saveWidgetData<String>(
        'gap_value',
        formatGap(result.gap),
      );
      await HomeWidget.saveWidgetData<String>(
        'updated_at',
        formatDate(result.calculatedAt),
      );
    }

    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
      iOSName: iOSWidgetName,
    );
  }
}

final widgetServiceProvider = Provider<WidgetService>(
  (ref) => WidgetService(),
);
