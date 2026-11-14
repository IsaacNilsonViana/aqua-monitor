/// Contrato BLE compartilhado entre o app e o firmware do ESP32.
///
/// O ESP32 deve anunciar [serviceUuid] e enviar notificacoes UTF-8 pela
/// caracteristica [dataCharacteristicUuid]. Veja `firmware/esp32_example.ino`.
abstract final class BleConfig {
  static const serviceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const dataCharacteristicUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
  static const commandCharacteristicUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  static const preferredDeviceName = 'AquaSensor';
  static const reconnectAttempts = 5;
  static const reconnectBaseDelay = Duration(seconds: 2);
}
