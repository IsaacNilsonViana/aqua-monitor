import 'package:aqua_monitor/models/water_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifica leitura adequada', () {
    final reading = WaterReading(
      ph: 7,
      turbidity: 2,
      tds: 250,
      dissolvedOxygen: 6.2,
      timestamp: DateTime(2026),
    );
    expect(reading.overallQuality, WaterQuality.adequate);
  });

  test('o pior parametro determina a classificacao geral', () {
    final reading = WaterReading(
      ph: 7,
      turbidity: 20,
      tds: 250,
      dissolvedOxygen: 6.2,
      timestamp: DateTime(2026),
    );
    expect(reading.overallQuality, WaterQuality.alert);
  });

  test('oxigenio baixo determina alerta geral', () {
    final reading = WaterReading(
      ph: 7,
      turbidity: 2,
      tds: 250,
      dissolvedOxygen: 2.5,
      timestamp: DateTime(2026),
    );
    expect(reading.overallQuality, WaterQuality.alert);
  });
}
