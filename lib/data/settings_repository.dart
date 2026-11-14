import 'package:shared_preferences/shared_preferences.dart';

import '../models/water_quality_settings.dart';

class SettingsRepository {
  SettingsRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static const _prefix = 'quality_settings.';

  Future<WaterQualitySettings> load() async {
    const defaults = WaterQualitySettings();
    return WaterQualitySettings(
      phIdealMin: await _preferences.getDouble('${_prefix}phIdealMin') ??
          defaults.phIdealMin,
      phIdealMax: await _preferences.getDouble('${_prefix}phIdealMax') ??
          defaults.phIdealMax,
      phCriticalMin: await _preferences.getDouble('${_prefix}phCriticalMin') ??
          defaults.phCriticalMin,
      phCriticalMax: await _preferences.getDouble('${_prefix}phCriticalMax') ??
          defaults.phCriticalMax,
      turbidityIdealMax:
          await _preferences.getDouble('${_prefix}turbidityIdealMax') ??
              defaults.turbidityIdealMax,
      turbidityCriticalMax:
          await _preferences.getDouble('${_prefix}turbidityCriticalMax') ??
              defaults.turbidityCriticalMax,
      tdsIdealMax: await _preferences.getDouble('${_prefix}tdsIdealMax') ??
          defaults.tdsIdealMax,
      tdsCriticalMax:
          await _preferences.getDouble('${_prefix}tdsCriticalMax') ??
              defaults.tdsCriticalMax,
      oxygenIdealMin:
          await _preferences.getDouble('${_prefix}oxygenIdealMin') ??
              defaults.oxygenIdealMin,
      oxygenCriticalMin:
          await _preferences.getDouble('${_prefix}oxygenCriticalMin') ??
              defaults.oxygenCriticalMin,
      notificationsEnabled:
          await _preferences.getBool('${_prefix}notificationsEnabled') ??
              defaults.notificationsEnabled,
      notifyAttention:
          await _preferences.getBool('${_prefix}notifyAttention') ??
              defaults.notifyAttention,
      notificationCooldownMinutes:
          await _preferences.getInt('${_prefix}cooldownMinutes') ??
              defaults.notificationCooldownMinutes,
      backgroundMonitoringEnabled:
          await _preferences.getBool('${_prefix}backgroundMonitoringEnabled') ??
              defaults.backgroundMonitoringEnabled,
      backgroundNotificationDetailsEnabled: await _preferences
              .getBool('${_prefix}backgroundNotificationDetailsEnabled') ??
          defaults.backgroundNotificationDetailsEnabled,
    );
  }

  Future<void> save(WaterQualitySettings settings) async {
    await Future.wait([
      _preferences.setDouble('${_prefix}phIdealMin', settings.phIdealMin),
      _preferences.setDouble('${_prefix}phIdealMax', settings.phIdealMax),
      _preferences.setDouble(
        '${_prefix}phCriticalMin',
        settings.phCriticalMin,
      ),
      _preferences.setDouble(
        '${_prefix}phCriticalMax',
        settings.phCriticalMax,
      ),
      _preferences.setDouble(
        '${_prefix}turbidityIdealMax',
        settings.turbidityIdealMax,
      ),
      _preferences.setDouble(
        '${_prefix}turbidityCriticalMax',
        settings.turbidityCriticalMax,
      ),
      _preferences.setDouble('${_prefix}tdsIdealMax', settings.tdsIdealMax),
      _preferences.setDouble(
        '${_prefix}tdsCriticalMax',
        settings.tdsCriticalMax,
      ),
      _preferences.setDouble(
        '${_prefix}oxygenIdealMin',
        settings.oxygenIdealMin,
      ),
      _preferences.setDouble(
        '${_prefix}oxygenCriticalMin',
        settings.oxygenCriticalMin,
      ),
      _preferences.setBool(
        '${_prefix}notificationsEnabled',
        settings.notificationsEnabled,
      ),
      _preferences.setBool(
        '${_prefix}notifyAttention',
        settings.notifyAttention,
      ),
      _preferences.setInt(
        '${_prefix}cooldownMinutes',
        settings.notificationCooldownMinutes,
      ),
      _preferences.setBool(
        '${_prefix}backgroundMonitoringEnabled',
        settings.backgroundMonitoringEnabled,
      ),
      _preferences.setBool(
        '${_prefix}backgroundNotificationDetailsEnabled',
        settings.backgroundNotificationDetailsEnabled,
      ),
    ]);
  }
}
