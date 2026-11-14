import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'controllers/water_monitor_controller.dart';
import 'data/local_database.dart';
import 'data/reading_repository.dart';
import 'data/settings_repository.dart';
import 'services/ble_water_service.dart';
import 'services/background_monitoring_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  final database = LocalDatabase();
  final repository = ReadingRepository(database);
  final settingsRepository = SettingsRepository();
  final bleService = BleWaterService();
  final notificationService = NotificationService();
  final backgroundMonitoringService = BackgroundMonitoringService();
  final controller = WaterMonitorController(
    bleService: bleService,
    repository: repository,
    settingsRepository: settingsRepository,
    notificationService: notificationService,
    backgroundMonitoringService: backgroundMonitoringService,
  );
  await controller.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: controller,
      child: const AquaMonitorApp(),
    ),
  );

  if (controller.settings.notificationsEnabled) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.requestNotificationPermission());
    });
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (controller.settings.backgroundMonitoringEnabled) {
      unawaited(controller.startBackgroundMonitoring());
    }
  });
}
