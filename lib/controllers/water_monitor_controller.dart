import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/reading_repository.dart';
import '../data/settings_repository.dart';
import '../models/connection_status.dart';
import '../models/sensor_device.dart';
import '../models/water_reading.dart';
import '../models/water_quality_settings.dart';
import '../services/ble_water_service.dart';
import '../services/background_monitoring_service.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';

class WaterMonitorController extends ChangeNotifier {
  WaterMonitorController({
    required BleWaterService bleService,
    required ReadingRepository repository,
    required SettingsRepository settingsRepository,
    required NotificationService notificationService,
    required BackgroundMonitoringService backgroundMonitoringService,
    ExportService? exportService,
  })  : _bleService = bleService,
        _repository = repository,
        _settingsRepository = settingsRepository,
        _notificationService = notificationService,
        _backgroundMonitoringService = backgroundMonitoringService,
        _exportService = exportService ?? ExportService();

  final BleWaterService _bleService;
  final ReadingRepository _repository;
  final SettingsRepository _settingsRepository;
  final NotificationService _notificationService;
  final BackgroundMonitoringService _backgroundMonitoringService;
  final ExportService _exportService;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  final List<SensorDevice> _devices = [];
  final List<WaterReading> _history = [];
  WaterReading? _currentReading;
  SensorConnectionStatus _status = SensorConnectionStatus.disconnected;
  String? _message;
  bool _autoSave = true;
  bool _historyLoading = false;
  DateTime? _lastAutoSave;
  DateTime? _lastNotification;
  WaterQualitySettings _settings = const WaterQualitySettings();
  int _sessionReadingCount = 0;
  bool _backgroundMonitoringRunning = false;

  UnmodifiableListView<SensorDevice> get devices =>
      UnmodifiableListView(_devices);
  UnmodifiableListView<WaterReading> get history =>
      UnmodifiableListView(_history);
  WaterReading? get currentReading => _currentReading;
  SensorConnectionStatus get status => _status;
  String? get message => _message;
  bool get autoSave => _autoSave;
  bool get historyLoading => _historyLoading;
  bool get isConnected => _status == SensorConnectionStatus.connected;
  bool get isDemo => _status == SensorConnectionStatus.demo;
  WaterQualitySettings get settings => _settings;
  bool get backgroundMonitoringRunning => _backgroundMonitoringRunning;

  Future<void> initialize() async {
    _settings = await _settingsRepository.load();
    await _notificationService.initialize();
    await _backgroundMonitoringService.initialize();
    _backgroundMonitoringRunning =
        await _backgroundMonitoringService.isRunning();
    _subscriptions.add(_bleService.devices.listen((items) {
      _devices
        ..clear()
        ..addAll(items);
      notifyListeners();
    }));
    _subscriptions.add(_bleService.status.listen((value) {
      _status = value;
      notifyListeners();
      unawaited(_updateBackgroundStatus());
    }));
    _subscriptions.add(_bleService.messages.listen((value) {
      _message = value;
      notifyListeners();
    }));
    _subscriptions.add(_bleService.readings.listen(_onReading));
    await refreshHistory();
  }

  Future<void> _onReading(WaterReading reading) async {
    _currentReading = reading;
    _sessionReadingCount++;
    notifyListeners();
    await _updateBackgroundStatus();
    await _notifyIfNeeded(reading);
    if (!_autoSave) return;

    // Sensores podem publicar muitas vezes por segundo. Uma amostra persistida
    // a cada 5 s preserva o historico sem fazer o banco crescer indefinidamente.
    final now = DateTime.now();
    if (_lastAutoSave == null ||
        now.difference(_lastAutoSave!) >= const Duration(seconds: 5)) {
      _lastAutoSave = now;
      await _save(reading);
    }
  }

  Future<bool> startBackgroundMonitoring() async {
    if (!_settings.backgroundMonitoringEnabled) return false;
    final started = await _backgroundMonitoringService.start();
    _backgroundMonitoringRunning = started;
    if (started) await _updateBackgroundStatus();
    notifyListeners();
    return started;
  }

  Future<bool> stopBackgroundMonitoring() async {
    final stopped = await _backgroundMonitoringService.stop();
    if (stopped) _backgroundMonitoringRunning = false;
    notifyListeners();
    return stopped;
  }

  Future<void> _updateBackgroundStatus() => _backgroundMonitoringService.update(
        status: _status,
        readingCount: _sessionReadingCount,
        showReadingValues: _settings.backgroundNotificationDetailsEnabled,
        reading: _currentReading,
      );

  Future<bool> isBackgroundMonitoringRunning() =>
      _backgroundMonitoringService.isRunning();

  Future<bool> configureBackgroundBattery() =>
      _backgroundMonitoringService.requestBatteryOptimizationExemption();

  Future<void> _notifyIfNeeded(WaterReading reading) async {
    if (!_settings.notificationsEnabled) return;
    final issues = _qualityIssues(reading);
    if (issues.isEmpty) return;

    final now = DateTime.now();
    final cooldown = Duration(
      minutes: _settings.notificationCooldownMinutes,
    );
    if (_lastNotification != null &&
        now.difference(_lastNotification!) < cooldown) {
      return;
    }
    _lastNotification = now;
    try {
      await _notificationService.showQualityAlert(issues.join(' | '));
    } catch (error) {
      _message = 'Falha ao exibir notificacao: $error';
      notifyListeners();
    }
  }

  List<String> _qualityIssues(WaterReading reading) {
    final issues = <String>[];

    void addIssue(
      String name,
      String value,
      WaterQuality quality,
    ) {
      final shouldNotify = quality == WaterQuality.alert ||
          (_settings.notifyAttention && quality == WaterQuality.attention);
      if (!shouldNotify) return;
      final level = quality == WaterQuality.alert ? 'critico' : 'atencao';
      issues.add('$name $value ($level)');
    }

    addIssue(
      'pH',
      reading.ph.toStringAsFixed(2),
      reading.phQualityFor(_settings),
    );
    addIssue(
      'Turbidez',
      '${reading.turbidity.toStringAsFixed(1)} NTU',
      reading.turbidityQualityFor(_settings),
    );
    addIssue(
      'TDS',
      '${reading.tds.toStringAsFixed(0)} ppm',
      reading.tdsQualityFor(_settings),
    );
    final oxygen = reading.dissolvedOxygen;
    final oxygenQuality = reading.oxygenQualityFor(_settings);
    if (oxygen != null && oxygenQuality != null) {
      addIssue(
        'Oxigenio',
        '${oxygen.toStringAsFixed(2)} mg/L',
        oxygenQuality,
      );
    }
    return issues;
  }

  Future<String?> updateSettings(WaterQualitySettings value) async {
    final validationError = value.validate();
    if (validationError != null) return validationError;
    _settings = value;
    await _settingsRepository.save(value);
    if (value.backgroundMonitoringEnabled) {
      final started = await startBackgroundMonitoring();
      if (!started) {
        _message = 'Nao foi possivel ativar o monitoramento em segundo plano.';
      }
    } else {
      final stopped = await stopBackgroundMonitoring();
      if (!stopped) {
        _message = 'Nao foi possivel parar o monitoramento em segundo plano.';
      }
    }
    if (value.notificationsEnabled) {
      final allowed = await _notificationService.requestPermission();
      if (!allowed) {
        _message = 'Ative as notificacoes do Aqua Monitor nas configuracoes '
            'do Android.';
      }
    }
    notifyListeners();
    return null;
  }

  Future<void> resetSettings() async {
    const defaults = WaterQualitySettings();
    await updateSettings(defaults);
  }

  Future<bool> sendTestNotification() async {
    final allowed = await _notificationService.requestPermission();
    if (!allowed) return false;
    await _notificationService.showQualityAlert(
      'Notificacao de teste. Os alertas estao funcionando.',
    );
    return true;
  }

  Future<bool> requestNotificationPermission() =>
      _notificationService.requestPermission();

  Future<void> startScan() => _bleService.startScan();
  Future<void> stopScan() => _bleService.stopScan();
  Future<void> connect(SensorDevice device) => _bleService.connect(device);
  Future<void> disconnect() => _bleService.disconnect();
  Future<void> startDemo() => _bleService.startDemo();

  Future<void> stopDemo() async {
    await _bleService.stopDemo();
    _status = SensorConnectionStatus.disconnected;
    notifyListeners();
    await _updateBackgroundStatus();
  }

  void setAutoSave(bool enabled) {
    _autoSave = enabled;
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  Future<bool> saveCurrentReading() async {
    final reading = _currentReading;
    if (reading == null) {
      _message = 'Ainda nao ha uma leitura para salvar.';
      notifyListeners();
      return false;
    }
    await _save(reading);
    _message = 'Leitura salva no historico.';
    notifyListeners();
    return true;
  }

  Future<void> _save(WaterReading reading) async {
    try {
      final saved = await _repository.insert(reading);
      _history.insert(0, saved);
      notifyListeners();
    } catch (error) {
      _message = 'Falha ao salvar leitura: $error';
      notifyListeners();
    }
  }

  Future<void> refreshHistory() async {
    _historyLoading = true;
    notifyListeners();
    try {
      final values = await _repository.getAll();
      _history
        ..clear()
        ..addAll(values);
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteReading(WaterReading reading) async {
    if (reading.id == null) return;
    final index = _history.indexWhere((item) => item.id == reading.id);
    if (index < 0) return;
    // O Dismissible exige que o item saia da lista no mesmo frame do gesto.
    _history.removeAt(index);
    notifyListeners();
    try {
      await _repository.delete(reading.id!);
    } catch (error) {
      _history.insert(index.clamp(0, _history.length), reading);
      _message = 'Falha ao excluir leitura: $error';
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    await _repository.clear();
    _history.clear();
    notifyListeners();
  }

  int countReadingsOlderThan(DateTime cutoff) =>
      _history.where((reading) => reading.timestamp.isBefore(cutoff)).length;

  Future<int> deleteReadingsOlderThan(DateTime cutoff) async {
    final count = countReadingsOlderThan(cutoff);
    if (count == 0) return 0;
    await _repository.deleteOlderThan(cutoff);
    _history.removeWhere((reading) => reading.timestamp.isBefore(cutoff));
    notifyListeners();
    return count;
  }

  Future<bool> export(ExportFormat format) async {
    if (_history.isEmpty) {
      _message = 'Nao ha leituras para exportar.';
      notifyListeners();
      return false;
    }
    try {
      await _exportService.share(_history, format);
      return true;
    } catch (error) {
      _message = 'Falha ao exportar: $error';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_bleService.dispose());
    super.dispose();
  }
}
