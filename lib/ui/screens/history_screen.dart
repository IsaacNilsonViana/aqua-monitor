import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/water_monitor_controller.dart';
import '../../models/water_reading.dart';
import '../../models/water_quality_settings.dart';
import '../../services/export_service.dart';
import '../../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WaterMonitorController>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${controller.history.length} leituras salvas',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<ExportFormat>(
                enabled: controller.history.isNotEmpty,
                tooltip: 'Exportar historico',
                onSelected: (format) => controller.export(format),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: ExportFormat.csv,
                    child: ListTile(
                      leading: Icon(Icons.table_view_outlined),
                      title: Text('Exportar CSV'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: ExportFormat.json,
                    child: ListTile(
                      leading: Icon(Icons.data_object),
                      title: Text('Exportar JSON'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.ios_share, size: 19),
                      SizedBox(width: 6),
                      Text('Exportar'),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Excluir dados antigos',
                onPressed: controller.history.isEmpty
                    ? null
                    : () => _showCleanupOptions(context, controller),
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: controller.historyLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.history.isEmpty
                  ? const _EmptyHistory()
                  : RefreshIndicator(
                      onRefresh: controller.refreshHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        itemCount: controller.history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final reading = controller.history[index];
                          return Dismissible(
                            key: ValueKey(reading.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDelete(context),
                            onDismissed: (_) =>
                                controller.deleteReading(reading),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 22),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: _HistoryTile(
                              reading: reading,
                              settings: controller.settings,
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Future<void> _showCleanupOptions(
    BuildContext context,
    WaterMonitorController controller,
  ) async {
    final selectedDays = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Excluir somente dados antigos',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Escolha quanto tempo de historico recente deseja preservar.',
              ),
            ),
            for (final days in const [7, 30, 90, 180])
              ListTile(
                leading: const Icon(Icons.history_toggle_off),
                title: Text('Manter os ultimos $days dias'),
                subtitle: Text('Excluir leituras com mais de $days dias'),
                onTap: () => Navigator.pop(sheetContext, days),
              ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Escolher uma data limite'),
              subtitle:
                  const Text('Preservar a data escolhida e as posteriores'),
              onTap: () => Navigator.pop(sheetContext, -1),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selectedDays == null || !context.mounted) return;

    DateTime cutoff;
    if (selectedDays == -1) {
      final now = DateTime.now();
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime(now.year, now.month, now.day),
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year, now.month, now.day),
        helpText: 'PRESERVAR LEITURAS A PARTIR DE',
        cancelText: 'Cancelar',
        confirmText: 'Selecionar',
      );
      if (selectedDate == null) return;
      cutoff = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    } else {
      cutoff = DateTime.now().subtract(Duration(days: selectedDays));
    }

    if (!context.mounted) return;
    final count = controller.countReadingsOlderThan(cutoff);
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao ha dados antigos nesse periodo.')),
      );
      return;
    }

    final cutoffLabel = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(cutoff);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir dados antigos?'),
        content: Text(
          '$count leituras anteriores a $cutoffLabel serao excluidas. '
          'As leituras mais recentes serao preservadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Excluir $count'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;

    try {
      final removed = await controller.deleteReadingsOlderThan(cutoff);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$removed leituras antigas excluidas.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel excluir os dados.')),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Excluir leitura?'),
            content: const Text('Esta acao nao pode ser desfeita.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.reading, required this.settings});

  final WaterReading reading;
  final WaterQualitySettings settings;

  @override
  Widget build(BuildContext context) {
    final overallQuality = reading.overallQualityFor(settings);
    final color = switch (overallQuality) {
      WaterQuality.adequate => AppColors.success,
      WaterQuality.attention => AppColors.warning,
      WaterQuality.alert => AppColors.danger,
    };
    final overallLabel = switch (overallQuality) {
      WaterQuality.adequate => null,
      WaterQuality.attention => 'Atencao',
      WaterQuality.alert => 'Critico',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    DateFormat("dd/MM/yyyy 'as' HH:mm:ss", 'pt_BR')
                        .format(reading.timestamp),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (overallLabel != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      overallLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (reading.source == 'demonstracao')
                  const Tooltip(
                    message: 'Leitura de demonstracao',
                    child: Icon(Icons.science_outlined,
                        size: 18, color: Colors.blueGrey),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Value(
                  label: 'Oxigenio dissolvido',
                  value: reading.dissolvedOxygen == null
                      ? '-- mg/L'
                      : '${reading.dissolvedOxygen!.toStringAsFixed(2)} mg/L',
                  quality: reading.oxygenQualityFor(settings),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _Value(
                  label: 'pH',
                  value: reading.ph.toStringAsFixed(2),
                  quality: reading.phQualityFor(settings),
                ),
                _Value(
                  label: 'Turbidez',
                  value: '${reading.turbidity.toStringAsFixed(1)} NTU',
                  quality: reading.turbidityQualityFor(settings),
                ),
                _Value(
                  label: 'TDS',
                  value: '${reading.tds.toStringAsFixed(0)} ppm',
                  quality: reading.tdsQualityFor(settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({
    required this.label,
    required this.value,
    this.quality,
  });

  final String label;
  final String value;
  final WaterQuality? quality;

  @override
  Widget build(BuildContext context) {
    final isMarked = quality != null && quality != WaterQuality.adequate;
    final color = switch (quality) {
      WaterQuality.attention => AppColors.warning,
      WaterQuality.alert => AppColors.danger,
      _ => Colors.blueGrey,
    };
    final status = switch (quality) {
      WaterQuality.attention => 'Atencao',
      WaterQuality.alert => 'Fora do limite',
      _ => null,
    };
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isMarked ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              isMarked ? Border.all(color: color.withValues(alpha: 0.6)) : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isMarked ? color : null,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    quality == WaterQuality.alert
                        ? Icons.error_outline
                        : Icons.warning_amber_rounded,
                    size: 13,
                    color: color,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 54, color: Colors.blueGrey),
            SizedBox(height: 12),
            Text(
              'Historico vazio',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 5),
            Text(
              'As leituras salvas aparecerao aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
