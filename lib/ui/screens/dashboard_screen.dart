import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/water_monitor_controller.dart';
import '../../models/water_reading.dart';
import '../../models/water_quality_settings.dart';
import '../../theme/app_theme.dart';
import '../widgets/quality_card.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WaterMonitorController>();
    final reading = controller.currentReading;
    final settings = controller.settings;

    return RefreshIndicator(
      onRefresh: controller.refreshHistory,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              StatusBadge(status: controller.status),
              const Spacer(),
              if (reading != null)
                Text(
                  DateFormat('HH:mm:ss').format(reading.timestamp),
                  style: const TextStyle(color: Colors.blueGrey),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _OverallPanel(reading: reading, settings: settings),
          const SizedBox(height: 12),
          if (reading == null)
            const _EmptyReading()
          else ...[
            QualityCard(
              title: 'pH',
              value: reading.ph.toStringAsFixed(2),
              unit: '',
              quality: reading.phQualityFor(settings),
              idealRange:
                  'Ideal: ${settings.phIdealMin} a ${settings.phIdealMax}',
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 10),
            QualityCard(
              title: 'Turbidez',
              value: reading.turbidity.toStringAsFixed(2),
              unit: 'NTU',
              quality: reading.turbidityQualityFor(settings),
              idealRange: 'Ideal: ate ${settings.turbidityIdealMax} NTU',
              icon: Icons.opacity,
            ),
            const SizedBox(height: 10),
            QualityCard(
              title: 'TDS',
              value: reading.tds.toStringAsFixed(0),
              unit: 'ppm',
              quality: reading.tdsQualityFor(settings),
              idealRange: 'Ideal: ate ${settings.tdsIdealMax} ppm',
              icon: Icons.grain,
            ),
            const SizedBox(height: 10),
            if (reading.dissolvedOxygen case final oxygen?)
              QualityCard(
                title: 'Oxigenio dissolvido',
                value: oxygen.toStringAsFixed(2),
                unit: 'mg/L',
                quality: reading.oxygenQualityFor(settings)!,
                idealRange:
                    'Ideal: a partir de ${settings.oxygenIdealMin} mg/L',
                icon: Icons.air,
              )
            else
              const _MissingOxygenCard(),
          ],
          const SizedBox(height: 14),
          Card(
            child: SwitchListTile(
              value: controller.autoSave,
              onChanged: controller.setAutoSave,
              title: const Text('Salvar automaticamente'),
              subtitle: const Text('Registra uma amostra a cada 5 segundos'),
              secondary: const Icon(Icons.save_outlined),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: reading == null
                ? null
                : () async {
                    final saved = await controller.saveCurrentReading();
                    if (context.mounted && saved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Leitura salva.')),
                      );
                    }
                  },
            icon: const Icon(Icons.add_chart),
            label: const Text('Salvar leitura agora'),
          ),
          const SizedBox(height: 14),
          Text(
            'Indicadores sao referencias configuraveis do projeto e nao '
            'substituem analise laboratorial ou norma sanitaria vigente.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}

class _OverallPanel extends StatelessWidget {
  const _OverallPanel({required this.reading, required this.settings});

  final WaterReading? reading;
  final WaterQualitySettings settings;

  @override
  Widget build(BuildContext context) {
    final quality = reading?.overallQualityFor(settings);
    final (label, subtitle, color, icon) = switch (quality) {
      WaterQuality.adequate => (
          'Parametros adequados',
          'Todas as leituras estao na faixa configurada',
          AppColors.success,
          Icons.check_circle_outline,
        ),
      WaterQuality.attention => (
          'Requer atencao',
          'Um ou mais parametros estao proximos do limite',
          AppColors.warning,
          Icons.warning_amber_rounded,
        ),
      WaterQuality.alert => (
          'Fora da faixa',
          'Verifique a coleta e os sensores',
          AppColors.danger,
          Icons.error_outline,
        ),
      null => (
          'Aguardando leitura',
          'Conecte um sensor ou use a demonstracao',
          AppColors.blue,
          Icons.sensors,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 42),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingOxygenCard extends StatelessWidget {
  const _MissingOxygenCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Icon(Icons.air, color: Colors.blueGrey, size: 30),
        title: Text('Oxigenio dissolvido'),
        subtitle: Text(
          'Sem dados. Atualize o firmware para enviar o campo oxygen.',
        ),
        trailing: Text(
          '-- mg/L',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EmptyReading extends StatelessWidget {
  const _EmptyReading();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.water_drop_outlined,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text(
              'Nenhum dado recebido',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              'Abra Pareamento para conectar o ESP32.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
