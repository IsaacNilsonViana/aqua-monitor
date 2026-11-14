import 'dart:convert';

import '../models/water_reading.dart';

/// Converte uma linha recebida do sensor em leitura.
/// Aceita JSON (`{"ph":7.1,"turbidity":2.0,"tds":220,"oxygen":6.4}`)
/// ou CSV (`7.1,2.0,220,6.4`). Oxigenio e opcional para manter compatibilidade
/// com firmwares antigos. Cada amostra deve terminar com `\n`.
class SensorPayloadParser {
  const SensorPayloadParser();

  WaterReading? parseLine(String line, {String source = 'sensor'}) {
    final normalized = line.trim();
    if (normalized.isEmpty) return null;

    try {
      late final double ph;
      late final double turbidity;
      late final double tds;
      double? oxygen;

      if (normalized.startsWith('{')) {
        final json = jsonDecode(normalized) as Map<String, dynamic>;
        ph = _asDouble(json['ph']);
        turbidity = _asDouble(json['turbidity'] ?? json['ntu']);
        tds = _asDouble(json['tds'] ?? json['ppm']);
        final oxygenValue = json['oxygen'] ??
            json['dissolved_oxygen'] ??
            json['do'] ??
            json['o2'];
        if (oxygenValue != null) oxygen = _asDouble(oxygenValue);
      } else {
        final parts = normalized.split(',');
        if (parts.length < 3) return null;
        ph = _asDouble(parts[0]);
        turbidity = _asDouble(parts[1]);
        tds = _asDouble(parts[2]);
        if (parts.length >= 4 && parts[3].trim().isNotEmpty) {
          oxygen = _asDouble(parts[3]);
        }
      }

      final reading = WaterReading(
        ph: ph,
        turbidity: turbidity,
        tds: tds,
        dissolvedOxygen: oxygen,
        timestamp: DateTime.now(),
        source: source,
      );
      return reading.hasValidRange ? reading : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.parse(value.trim().replaceAll(',', '.'));
    }
    throw const FormatException('Campo numerico ausente');
  }
}
