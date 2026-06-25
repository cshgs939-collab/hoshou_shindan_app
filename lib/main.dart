import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/widget_service.dart';
import 'data/repositories/hive_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.init();

  final widgetService = WidgetService();
  await widgetService.init();

  final repository = await initHiveRepository();
  await notificationService.syncFromSettings(repository.getSettings());

  final latest = repository.getHistory().isEmpty
      ? null
      : repository.getHistory().first;
  await widgetService.updateFromResult(latest);

  runApp(
    ProviderScope(
      overrides: [
        hiveRepositoryProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(notificationService),
        widgetServiceProvider.overrideWithValue(widgetService),
      ],
      child: const MamoruApp(),
    ),
  );
}
