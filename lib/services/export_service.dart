import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/water_reading.dart';

enum ExportFormat { csv, json }

class ExportService {
  Future<File> createFile(
    List<WaterReading> readings,
    ExportFormat format,
  ) async {
    final directory = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final extension = format == ExportFormat.csv ? 'csv' : 'json';
    final file = File(p.join(directory.path, 'aqua_monitor_$stamp.$extension'));

    if (format == ExportFormat.csv) {
      final buffer = StringBuffer(
        '\uFEFFdata_hora,ph,turbidez_ntu,tds_ppm,oxigenio_mg_l,origem\n',
      );
      for (final reading in readings) {
        buffer.writeln([
          reading.timestamp.toIso8601String(),
          reading.ph.toStringAsFixed(2),
          reading.turbidity.toStringAsFixed(2),
          reading.tds.toStringAsFixed(1),
          reading.dissolvedOxygen?.toStringAsFixed(2) ?? '',
          _csvEscape(reading.source),
        ].join(','));
      }
      await file.writeAsString(buffer.toString(), flush: true);
    } else {
      final encoder = const JsonEncoder.withIndent('  ');
      await file.writeAsString(
        encoder.convert(readings.map((item) => item.toMap()).toList()),
        flush: true,
      );
    }
    return file;
  }

  Future<void> share(List<WaterReading> readings, ExportFormat format) async {
    final file = await createFile(readings, format);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Historico Aqua Monitor',
        text: 'Exportacao das leituras de qualidade da agua.',
      ),
    );
  }

  String _csvEscape(String value) => '"${value.replaceAll('"', '""')}"';
}
