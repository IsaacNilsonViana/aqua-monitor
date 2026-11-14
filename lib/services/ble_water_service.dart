import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/ble_config.dart';
import '../models/connection_status.dart';
import '../models/sensor_device.dart';
import '../models/water_reading.dart';
import 'sensor_payload_parser.dart';

class BleWaterService {
  BleWaterService({FlutterReactiveBle? ble})
      : _ble = ble ?? FlutterReactiveBle();

  final FlutterReactiveBle _ble;
  final SensorPayloadParser _parser = const SensorPayloadParser();
  final _devicesController = StreamController<List<SensorDevice>>.broadcast();
  final _readingsController = StreamController<WaterReading>.broadcast();
  final _statusController =
      StreamController<SensorConnectionStatus>.broadcast();
  final _messageController = StreamController<String>.broadcast();

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  Timer? _reconnectTimer;
  Timer? _demoTimer;
  final Map<String, SensorDevice> _devices = {};

  String? _selectedDeviceId;
  String _textBuffer = '';
  int _reconnectAttempt = 0;
  bool _manualDisconnect = false;
  bool _disposed = false;

  Stream<List<SensorDevice>> get devices => _devicesController.stream;
  Stream<WaterReading> get readings => _readingsController.stream;
  Stream<SensorConnectionStatus> get status => _statusController.stream;
  Stream<String> get messages => _messageController.stream;

  Future<bool> requestPermissions() async {
    // Android 12+ usa Scan/Connect. Android 11 ou anterior exige localizacao
    // para descobrir dispositivos BLE. Permissoes nao aplicaveis sao ignoradas.
    final result = await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    final scanAllowed = result[Permission.bluetoothScan]?.isGranted ?? true;
    final connectAllowed =
        result[Permission.bluetoothConnect]?.isGranted ?? true;
    final locationAllowed =
        result[Permission.locationWhenInUse]?.isGranted ?? true;
    return (scanAllowed && connectAllowed) || locationAllowed;
  }

  Future<void> startScan() async {
    await stopDemo();
    final allowed = await requestPermissions();
    if (!allowed) {
      _emitStatus(SensorConnectionStatus.error);
      _emitMessage('Permissao de Bluetooth/localizacao negada.');
      return;
    }

    await _scanSubscription?.cancel();
    _devices.clear();
    _devicesController.add(const []);
    _emitStatus(SensorConnectionStatus.scanning);

    final service = Uuid.parse(BleConfig.serviceUuid);
    _scanSubscription = _ble.scanForDevices(
        withServices: [service], scanMode: ScanMode.lowLatency).listen(
      (device) {
        _devices[device.id] = SensorDevice(
          id: device.id,
          name: device.name,
          rssi: device.rssi,
        );
        final sorted = _devices.values.toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
        _devicesController.add(sorted);
      },
      onError: (Object error) {
        _emitStatus(SensorConnectionStatus.error);
        _emitMessage(_friendlyBleError(error));
      },
    );
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (_selectedDeviceId == null && _demoTimer == null) {
      _emitStatus(SensorConnectionStatus.disconnected);
    }
  }

  Future<void> connect(SensorDevice device) async {
    await stopDemo();
    await stopScan();
    await _cancelConnection();
    _manualDisconnect = false;
    _selectedDeviceId = device.id;
    _reconnectAttempt = 0;
    await _connectSelected(isReconnect: false);
  }

  Future<void> _connectSelected({required bool isReconnect}) async {
    final deviceId = _selectedDeviceId;
    if (deviceId == null || _disposed) return;

    _emitStatus(isReconnect
        ? SensorConnectionStatus.reconnecting
        : SensorConnectionStatus.connecting);
    _connectionSubscription = _ble
        .connectToDevice(
      id: deviceId,
      servicesWithCharacteristicsToDiscover: {
        Uuid.parse(BleConfig.serviceUuid): [
          Uuid.parse(BleConfig.dataCharacteristicUuid),
          Uuid.parse(BleConfig.commandCharacteristicUuid),
        ],
      },
      connectionTimeout: const Duration(seconds: 12),
    )
        .listen(
      (update) async {
        switch (update.connectionState) {
          case DeviceConnectionState.connected:
            _reconnectAttempt = 0;
            _emitStatus(SensorConnectionStatus.connected);
            _emitMessage('Sensor conectado.');
            await _subscribeToReadings(deviceId);
          case DeviceConnectionState.disconnected:
            await _notificationSubscription?.cancel();
            _notificationSubscription = null;
            if (!_manualDisconnect) _scheduleReconnect();
          case DeviceConnectionState.connecting:
            _emitStatus(SensorConnectionStatus.connecting);
          case DeviceConnectionState.disconnecting:
            break;
        }
      },
      onError: (Object error) {
        _emitMessage(_friendlyBleError(error));
        if (!_manualDisconnect) _scheduleReconnect();
      },
    );
  }

  Future<void> _subscribeToReadings(String deviceId) async {
    await _notificationSubscription?.cancel();
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(BleConfig.serviceUuid),
      characteristicId: Uuid.parse(BleConfig.dataCharacteristicUuid),
      deviceId: deviceId,
    );
    _notificationSubscription =
        _ble.subscribeToCharacteristic(characteristic).listen(
              _handleBytes,
              onError: (Object error) => _emitMessage(
                  'Falha ao receber dados: ${_friendlyBleError(error)}'),
            );
  }

  void _handleBytes(List<int> bytes) {
    _textBuffer += utf8.decode(bytes, allowMalformed: true);
    final lines = _textBuffer.split(RegExp(r'[\r\n]+'));
    _textBuffer = lines.removeLast();
    for (final line in lines) {
      final reading = _parser.parseLine(line);
      if (reading != null) {
        _readingsController.add(reading);
      } else if (line.trim().isNotEmpty) {
        _emitMessage('Pacote ignorado: formato de leitura invalido.');
      }
    }
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _selectedDeviceId == null || _disposed) return;
    if (_reconnectTimer?.isActive ?? false) return;
    if (_reconnectAttempt >= BleConfig.reconnectAttempts) {
      _emitStatus(SensorConnectionStatus.error);
      _emitMessage('Nao foi possivel reconectar ao sensor.');
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    _emitStatus(SensorConnectionStatus.reconnecting);
    final delay = BleConfig.reconnectBaseDelay * _reconnectAttempt;
    _emitMessage(
      'Conexao perdida. Nova tentativa $_reconnectAttempt/'
      '${BleConfig.reconnectAttempts} em ${delay.inSeconds}s.',
    );
    _reconnectTimer = Timer(delay, () async {
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      await _connectSelected(isReconnect: true);
    });
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _selectedDeviceId = null;
    await _cancelConnection();
    _emitStatus(SensorConnectionStatus.disconnected);
    _emitMessage('Sensor desconectado.');
  }

  Future<void> _cancelConnection() async {
    await _notificationSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _notificationSubscription = null;
    _connectionSubscription = null;
    _textBuffer = '';
  }

  /// Gera valores realistas para apresentacao e testes sem um ESP32 por perto.
  Future<void> startDemo() async {
    await stopScan();
    await disconnect();
    _manualDisconnect = true;
    _emitStatus(SensorConnectionStatus.demo);
    var tick = 0;
    final random = Random();
    _demoTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      tick++;
      _readingsController.add(
        WaterReading(
          ph: 7.15 + sin(tick / 4) * 0.28 + random.nextDouble() * 0.04,
          turbidity: 2.2 + sin(tick / 3) * 0.8 + random.nextDouble() * 0.15,
          tds: 245 + sin(tick / 5) * 24 + random.nextDouble() * 4,
          dissolvedOxygen:
              6.4 + sin(tick / 6) * 0.7 + random.nextDouble() * 0.12,
          timestamp: DateTime.now(),
          source: 'demonstracao',
        ),
      );
    });
    _emitMessage('Modo demonstracao iniciado.');
  }

  Future<void> stopDemo() async {
    _demoTimer?.cancel();
    _demoTimer = null;
  }

  String _friendlyBleError(Object error) {
    final text = error.toString();
    if (text.toLowerCase().contains('poweredoff')) {
      return 'Ative o Bluetooth do aparelho.';
    }
    return 'Erro de Bluetooth: $text';
  }

  void _emitStatus(SensorConnectionStatus value) {
    if (!_disposed) _statusController.add(value);
  }

  void _emitMessage(String value) {
    if (!_disposed) _messageController.add(value);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _demoTimer?.cancel();
    await _scanSubscription?.cancel();
    await _cancelConnection();
    await _devicesController.close();
    await _readingsController.close();
    await _statusController.close();
    await _messageController.close();
  }
}
