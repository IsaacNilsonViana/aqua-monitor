import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/water_monitor_controller.dart';
import '../../models/connection_status.dart';
import '../../models/sensor_device.dart';
import '../../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class PairingScreen extends StatelessWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WaterMonitorController>();
    final isScanning = controller.status == SensorConnectionStatus.scanning;
    final busy = controller.status == SensorConnectionStatus.connecting ||
        controller.status == SensorConnectionStatus.reconnecting;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Conexao do sensor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusBadge(status: controller.status),
                  ],
                ),
                if (controller.message != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: AppColors.blue),
                        const SizedBox(width: 8),
                        Expanded(child: Text(controller.message!)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: controller.clearMessage,
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (controller.isConnected || controller.isDemo)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: controller.isDemo
                          ? controller.stopDemo
                          : controller.disconnect,
                      icon: const Icon(Icons.link_off),
                      label: Text(controller.isDemo
                          ? 'Encerrar demonstracao'
                          : 'Desconectar'),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: busy
                              ? null
                              : isScanning
                                  ? controller.stopScan
                                  : controller.startScan,
                          icon: Icon(isScanning ? Icons.stop : Icons.radar),
                          label:
                              Text(isScanning ? 'Parar busca' : 'Buscar BLE'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : controller.startDemo,
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('Demonstracao'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'Sensores encontrados',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const Spacer(),
            if (isScanning)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (controller.devices.isEmpty)
          _EmptyDevices(isScanning: isScanning)
        else
          ...controller.devices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DeviceTile(
                device: device,
                onConnect: busy ? null : () => controller.connect(device),
              ),
            ),
          ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined, color: AppColors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ligue o ESP32 e habilite Bluetooth e Localizacao no '
                    'Android. O sensor deve anunciar o servico BLE definido '
                    'no arquivo lib/config/ble_config.dart.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onConnect});

  final SensorDevice device;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFDDF2F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.sensors, color: AppColors.blue),
        ),
        title: Text(
          device.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${device.id}\nSinal: ${device.rssi} dBm'),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: onConnect,
          style: FilledButton.styleFrom(
            minimumSize: const Size(82, 42),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Conectar'),
        ),
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices({required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.bluetooth_searching,
                size: 44, color: Colors.blueGrey),
            const SizedBox(height: 10),
            Text(
              isScanning
                  ? 'Procurando sensores proximos...'
                  : 'Toque em Buscar BLE para comecar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
