import 'package:aqua_monitor/models/water_quality.dart';
import 'package:aqua_monitor/models/water_quality_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifica oxigenio pelos limites configurados', () {
    const settings = WaterQualitySettings(
      oxygenIdealMin: 6,
      oxygenCriticalMin: 4,
    );
    expect(settings.oxygenQuality(6.1), WaterQuality.adequate);
    expect(settings.oxygenQuality(5), WaterQuality.attention);
    expect(settings.oxygenQuality(3.9), WaterQuality.alert);
  });

  test('rejeita limites inconsistentes', () {
    const settings = WaterQualitySettings(
      turbidityIdealMax: 10,
      turbidityCriticalMax: 5,
    );
    expect(settings.validate(), isNotNull);
  });

  test('preserva e altera configuracoes de segundo plano no copyWith', () {
    const settings = WaterQualitySettings();
    final disabled = settings.copyWith(
      backgroundMonitoringEnabled: false,
      backgroundNotificationDetailsEnabled: false,
    );

    expect(disabled.backgroundMonitoringEnabled, isFalse);
    expect(disabled.backgroundNotificationDetailsEnabled, isFalse);
    expect(disabled.phIdealMin, settings.phIdealMin);
  });
}
