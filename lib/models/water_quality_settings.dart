import 'water_quality.dart';

class WaterQualitySettings {
  const WaterQualitySettings({
    this.phIdealMin = 6.5,
    this.phIdealMax = 8.5,
    this.phCriticalMin = 6.0,
    this.phCriticalMax = 9.0,
    this.turbidityIdealMax = 5.0,
    this.turbidityCriticalMax = 10.0,
    this.tdsIdealMax = 500.0,
    this.tdsCriticalMax = 1000.0,
    this.oxygenIdealMin = 5.0,
    this.oxygenCriticalMin = 3.0,
    this.notificationsEnabled = true,
    this.notifyAttention = true,
    this.notificationCooldownMinutes = 5,
    this.backgroundMonitoringEnabled = true,
    this.backgroundNotificationDetailsEnabled = true,
  });

  final double phIdealMin;
  final double phIdealMax;
  final double phCriticalMin;
  final double phCriticalMax;
  final double turbidityIdealMax;
  final double turbidityCriticalMax;
  final double tdsIdealMax;
  final double tdsCriticalMax;
  final double oxygenIdealMin;
  final double oxygenCriticalMin;
  final bool notificationsEnabled;
  final bool notifyAttention;
  final int notificationCooldownMinutes;
  final bool backgroundMonitoringEnabled;
  final bool backgroundNotificationDetailsEnabled;

  String? validate() {
    if (phCriticalMin > phIdealMin ||
        phIdealMin >= phIdealMax ||
        phIdealMax > phCriticalMax) {
      return 'No pH, use: critico minimo <= ideal minimo < ideal maximo '
          '<= critico maximo.';
    }
    if (turbidityIdealMax <= 0 || turbidityIdealMax > turbidityCriticalMax) {
      return 'O limite critico de turbidez deve ser maior ou igual ao ideal.';
    }
    if (tdsIdealMax <= 0 || tdsIdealMax > tdsCriticalMax) {
      return 'O limite critico de TDS deve ser maior ou igual ao ideal.';
    }
    if (oxygenCriticalMin < 0 || oxygenCriticalMin > oxygenIdealMin) {
      return 'O minimo critico de oxigenio deve ser menor ou igual ao ideal.';
    }
    if (notificationCooldownMinutes < 1 || notificationCooldownMinutes > 1440) {
      return 'O intervalo de notificacoes deve ficar entre 1 e 1440 minutos.';
    }
    return null;
  }

  WaterQuality phQuality(double value) {
    if (value >= phIdealMin && value <= phIdealMax) {
      return WaterQuality.adequate;
    }
    if (value >= phCriticalMin && value <= phCriticalMax) {
      return WaterQuality.attention;
    }
    return WaterQuality.alert;
  }

  WaterQuality turbidityQuality(double value) {
    if (value <= turbidityIdealMax) return WaterQuality.adequate;
    if (value <= turbidityCriticalMax) return WaterQuality.attention;
    return WaterQuality.alert;
  }

  WaterQuality tdsQuality(double value) {
    if (value <= tdsIdealMax) return WaterQuality.adequate;
    if (value <= tdsCriticalMax) return WaterQuality.attention;
    return WaterQuality.alert;
  }

  WaterQuality oxygenQuality(double value) {
    if (value >= oxygenIdealMin) return WaterQuality.adequate;
    if (value >= oxygenCriticalMin) return WaterQuality.attention;
    return WaterQuality.alert;
  }

  WaterQualitySettings copyWith({
    double? phIdealMin,
    double? phIdealMax,
    double? phCriticalMin,
    double? phCriticalMax,
    double? turbidityIdealMax,
    double? turbidityCriticalMax,
    double? tdsIdealMax,
    double? tdsCriticalMax,
    double? oxygenIdealMin,
    double? oxygenCriticalMin,
    bool? notificationsEnabled,
    bool? notifyAttention,
    int? notificationCooldownMinutes,
    bool? backgroundMonitoringEnabled,
    bool? backgroundNotificationDetailsEnabled,
  }) {
    return WaterQualitySettings(
      phIdealMin: phIdealMin ?? this.phIdealMin,
      phIdealMax: phIdealMax ?? this.phIdealMax,
      phCriticalMin: phCriticalMin ?? this.phCriticalMin,
      phCriticalMax: phCriticalMax ?? this.phCriticalMax,
      turbidityIdealMax: turbidityIdealMax ?? this.turbidityIdealMax,
      turbidityCriticalMax: turbidityCriticalMax ?? this.turbidityCriticalMax,
      tdsIdealMax: tdsIdealMax ?? this.tdsIdealMax,
      tdsCriticalMax: tdsCriticalMax ?? this.tdsCriticalMax,
      oxygenIdealMin: oxygenIdealMin ?? this.oxygenIdealMin,
      oxygenCriticalMin: oxygenCriticalMin ?? this.oxygenCriticalMin,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyAttention: notifyAttention ?? this.notifyAttention,
      notificationCooldownMinutes:
          notificationCooldownMinutes ?? this.notificationCooldownMinutes,
      backgroundMonitoringEnabled:
          backgroundMonitoringEnabled ?? this.backgroundMonitoringEnabled,
      backgroundNotificationDetailsEnabled:
          backgroundNotificationDetailsEnabled ??
              this.backgroundNotificationDetailsEnabled,
    );
  }
}
