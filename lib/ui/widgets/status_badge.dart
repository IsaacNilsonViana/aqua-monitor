import 'package:flutter/material.dart';

import '../../models/connection_status.dart';
import '../../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final SensorConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      SensorConnectionStatus.connected => (
          'Conectado',
          AppColors.success,
          Icons.bluetooth_connected
        ),
      SensorConnectionStatus.scanning => (
          'Procurando',
          AppColors.blue,
          Icons.radar
        ),
      SensorConnectionStatus.connecting => (
          'Conectando',
          AppColors.blue,
          Icons.bluetooth_searching
        ),
      SensorConnectionStatus.reconnecting => (
          'Reconectando',
          AppColors.warning,
          Icons.sync
        ),
      SensorConnectionStatus.demo => (
          'Demonstracao',
          AppColors.blue,
          Icons.science_outlined
        ),
      SensorConnectionStatus.error => (
          'Atencao',
          AppColors.danger,
          Icons.error_outline
        ),
      SensorConnectionStatus.disconnected => (
          'Desconectado',
          Colors.blueGrey,
          Icons.bluetooth_disabled
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
