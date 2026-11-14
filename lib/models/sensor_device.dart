class SensorDevice {
  const SensorDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  final String id;
  final String name;
  final int rssi;

  String get displayName => name.trim().isEmpty ? 'Dispositivo sem nome' : name;
}
