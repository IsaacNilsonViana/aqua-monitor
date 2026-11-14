import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../models/connection_status.dart';
import '../models/water_reading.dart';

@pragma('vm:entry-point')
void monitoringStartCallback() {
  FlutterForegroundTask.setTaskHandler(MonitoringTaskHandler());
}

class MonitoringTaskHandler extends TaskHandler {
  DateTime _startedAt = DateTime.now();
  DateTime? _lastReadingAt;
  String _status = SensorConnectionStatus.disconnected.name;
  int _readingCount = 0;
  String _lastValues = '';
  bool _showReadingValues = true;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _startedAt = timestamp;
    await _refreshNotification(timestamp);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_refreshNotification(timestamp));
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final values = Map<String, dynamic>.from(data);
    _status = values['status'] as String? ?? _status;
    _readingCount = values['readingCount'] as int? ?? _readingCount;
    _lastValues = values['lastValues'] as String? ?? _lastValues;
    _showReadingValues =
        values['showReadingValues'] as bool? ?? _showReadingValues;
    final startedAtMillis = values['startedAtMillis'] as int?;
    final lastReadingMillis = values['lastReadingMillis'] as int?;
    if (startedAtMillis != null) {
      _startedAt = DateTime.fromMillisecondsSinceEpoch(startedAtMillis);
    }
    if (lastReadingMillis != null) {
      _lastReadingAt = DateTime.fromMillisecondsSinceEpoch(lastReadingMillis);
    }
    unawaited(_refreshNotification(DateTime.now()));
  }

  Future<void> _refreshNotification(DateTime now) async {
    var effectiveStatus = _status;
    final lastReadingAt = _lastReadingAt;
    if ((_status == SensorConnectionStatus.connected.name ||
            _status == SensorConnectionStatus.demo.name) &&
        lastReadingAt != null &&
        now.difference(lastReadingAt) > const Duration(seconds: 20)) {
      effectiveStatus = 'signalLost';
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: _titleFor(effectiveStatus),
      notificationText: _textFor(now, effectiveStatus),
    );
  }

  String _titleFor(String status) {
    return switch (status) {
      'connected' || 'demo' => 'Aqua Monitor • Captando',
      'connecting' => 'Aqua Monitor • Conectando',
      'reconnecting' => 'Aqua Monitor • Reconectando',
      'scanning' => 'Aqua Monitor • Procurando sensor',
      'signalLost' => 'Aqua Monitor • Sinal interrompido',
      'error' => 'Aqua Monitor • Falha na conexao',
      _ => 'Aqua Monitor • Sem conexao',
    };
  }

  String _textFor(DateTime now, String status) {
    final uptime = _formatDuration(now.difference(_startedAt));
    if (status == 'connected' || status == 'demo') {
      if (!_showReadingValues) {
        return 'Ativo ha $uptime • $_readingCount leituras recebidas';
      }
      final values =
          _lastValues.isEmpty ? 'aguardando primeira leitura' : _lastValues;
      return 'Ativo ha $uptime • $_readingCount leituras • $values';
    }
    if (status == 'signalLost') {
      return 'Ativo ha $uptime • sem dados recentes • tentando manter a captura';
    }
    return 'Ativo ha $uptime • $_readingCount leituras • aguardando conexao';
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (days > 0) return '${days}d ${hours}h';
    if (duration.inHours > 0) return '${duration.inHours}h ${minutes}min';
    return '${duration.inMinutes}min ${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

class BackgroundMonitoringService {
  bool _initialized = false;

  bool get isSupported => Platform.isAndroid;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'aqua_monitoring_service',
        channelName: 'Monitoramento em segundo plano',
        channelDescription:
            'Mantem a conexao com o sensor e mostra o estado da captura.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        showWhen: true,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
        allowAutoRestart: true,
        stopWithTask: false,
      ),
    );
    _initialized = true;
  }

  Future<bool> start() async {
    if (!isSupported) return false;
    await initialize();

    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (await FlutterForegroundTask.isRunningService) {
      unawaited(requestBatteryOptimizationExemption());
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 4201,
      serviceTypes: const [ForegroundServiceTypes.connectedDevice],
      notificationTitle: 'Aqua Monitor • Sem conexao',
      notificationText: 'Monitoramento iniciado • aguardando sensor',
      notificationInitialRoute: '/',
      callback: monitoringStartCallback,
    );
    final started = result is ServiceRequestSuccess;
    if (started) {
      // O servico deve existir antes de abrir a tela de bateria. Alguns
      // fabricantes, como Xiaomi/HyperOS, mantem essa tela aberta ate o usuario
      // escolher uma opcao e poderiam bloquear o inicio do monitoramento.
      unawaited(requestBatteryOptimizationExemption());
    }
    return started;
  }

  Future<bool> stop() async {
    if (!isSupported || !await FlutterForegroundTask.isRunningService) {
      return true;
    }
    final result = await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }

  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        return true;
      }
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      return await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    } catch (_) {
      // A captura ainda funciona como foreground service. O usuario pode
      // liberar a bateria manualmente nas configuracoes do Android.
      return false;
    }
  }

  Future<void> update({
    required SensorConnectionStatus status,
    required int readingCount,
    required bool showReadingValues,
    WaterReading? reading,
  }) async {
    if (!isSupported || !await FlutterForegroundTask.isRunningService) return;
    final oxygen = reading?.dissolvedOxygen;
    final lastValues = reading == null
        ? ''
        : 'pH ${reading.ph.toStringAsFixed(1)}, '
            'O2 ${oxygen?.toStringAsFixed(1) ?? '--'} mg/L';
    FlutterForegroundTask.sendDataToTask({
      'status': status.name,
      'readingCount': readingCount,
      'lastValues': lastValues,
      'showReadingValues': showReadingValues,
      if (reading != null)
        'lastReadingMillis': reading.timestamp.millisecondsSinceEpoch,
    });
  }

  Future<bool> isRunning() async =>
      isSupported && await FlutterForegroundTask.isRunningService;
}
