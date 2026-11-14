import 'package:sqflite/sqflite.dart';

import '../models/water_reading.dart';
import 'local_database.dart';

class ReadingRepository {
  ReadingRepository(this._localDatabase);

  final LocalDatabase _localDatabase;

  Future<WaterReading> insert(WaterReading reading) async {
    final db = await _localDatabase.database;
    final values = Map<String, Object?>.from(reading.toMap())..remove('id');
    final id = await db.insert(
      'readings',
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return WaterReading(
      id: id,
      ph: reading.ph,
      turbidity: reading.turbidity,
      tds: reading.tds,
      dissolvedOxygen: reading.dissolvedOxygen,
      timestamp: reading.timestamp,
      source: reading.source,
    );
  }

  Future<List<WaterReading>> getAll() async {
    final db = await _localDatabase.database;
    final rows = await db.query('readings', orderBy: 'timestamp DESC');
    return rows.map(WaterReading.fromMap).toList(growable: false);
  }

  Future<void> delete(int id) async {
    final db = await _localDatabase.database;
    await db.delete('readings', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await _localDatabase.database;
    await db.delete('readings');
  }

  Future<int> deleteOlderThan(DateTime cutoff) async {
    final db = await _localDatabase.database;
    return db.delete(
      'readings',
      where: 'timestamp < ?',
      whereArgs: [cutoff.toUtc().toIso8601String()],
    );
  }
}
