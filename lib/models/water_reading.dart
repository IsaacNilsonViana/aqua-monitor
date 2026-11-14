import 'water_quality.dart';
import 'water_quality_settings.dart';

export 'water_quality.dart';

class WaterReading {
  const WaterReading({
    this.id,
    required this.ph,
    required this.turbidity,
    required this.tds,
    this.dissolvedOxygen,
    required this.timestamp,
    this.source = 'sensor',
  });

  final int? id;
  final double ph;
  final double turbidity;
  final double tds;
  final double? dissolvedOxygen;
  final DateTime timestamp;
  final String source;

  bool get hasValidRange =>
      ph >= 0 &&
      ph <= 14 &&
      turbidity >= 0 &&
      tds >= 0 &&
      (dissolvedOxygen == null || dissolvedOxygen! >= 0);

  WaterQuality get phQuality {
    return phQualityFor(const WaterQualitySettings());
  }

  WaterQuality phQualityFor(WaterQualitySettings settings) =>
      settings.phQuality(ph);

  WaterQuality get turbidityQuality {
    return turbidityQualityFor(const WaterQualitySettings());
  }

  WaterQuality turbidityQualityFor(WaterQualitySettings settings) =>
      settings.turbidityQuality(turbidity);

  WaterQuality get tdsQuality {
    return tdsQualityFor(const WaterQualitySettings());
  }

  WaterQuality tdsQualityFor(WaterQualitySettings settings) =>
      settings.tdsQuality(tds);

  WaterQuality? oxygenQualityFor(WaterQualitySettings settings) {
    final value = dissolvedOxygen;
    return value == null ? null : settings.oxygenQuality(value);
  }

  WaterQuality get overallQuality {
    return overallQualityFor(const WaterQualitySettings());
  }

  WaterQuality overallQualityFor(WaterQualitySettings settings) {
    final oxygenQuality = oxygenQualityFor(settings);
    final qualities = <WaterQuality>[
      phQualityFor(settings),
      turbidityQualityFor(settings),
      tdsQualityFor(settings),
      if (oxygenQuality != null) oxygenQuality,
    ];
    if (qualities.contains(WaterQuality.alert)) return WaterQuality.alert;
    if (qualities.contains(WaterQuality.attention)) {
      return WaterQuality.attention;
    }
    return WaterQuality.adequate;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'ph': ph,
        'turbidity': turbidity,
        'tds': tds,
        'oxygen': dissolvedOxygen,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'source': source,
      };

  factory WaterReading.fromMap(Map<String, Object?> map) => WaterReading(
        id: map['id'] as int?,
        ph: (map['ph'] as num).toDouble(),
        turbidity: (map['turbidity'] as num).toDouble(),
        tds: (map['tds'] as num).toDouble(),
        dissolvedOxygen: (map['oxygen'] as num?)?.toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String).toLocal(),
        source: (map['source'] as String?) ?? 'sensor',
      );
}
