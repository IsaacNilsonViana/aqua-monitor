import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('notification_icon'),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    if (!_initialized) await initialize();
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  Future<void> showQualityAlert(String body) async {
    if (!_initialized) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'water_quality_alerts',
        'Alertas de qualidade da agua',
        channelDescription:
            'Avisa quando um parametro sai dos limites configurados.',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        enableVibration: true,
        color: Color(0xFFC8404D),
      ),
    );
    await _plugin.show(
      id: 4101,
      title: 'Alerta de qualidade da agua',
      body: body,
      notificationDetails: details,
      payload: 'quality_alert',
    );
  }
}
