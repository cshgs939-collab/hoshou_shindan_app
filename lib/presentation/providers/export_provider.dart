import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/export/diagnosis_json_exporter.dart';
import '../../data/export/diagnosis_pdf_exporter.dart';
import '../../data/repositories/hive_repository.dart';

final pdfExporterProvider = Provider<DiagnosisPdfExporter>(
  (ref) => DiagnosisPdfExporter(),
);

final jsonExporterProvider = Provider<DiagnosisJsonExporter>(
  (ref) => DiagnosisJsonExporter(ref.watch(hiveRepositoryProvider)),
);
