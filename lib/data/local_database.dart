import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final basePath = await getDatabasesPath();
    _database = await openDatabase(
      p.join(basePath, 'aqua_monitor.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE readings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ph REAL NOT NULL,
            turbidity REAL NOT NULL,
            tds REAL NOT NULL,
            oxygen REAL,
            timestamp TEXT NOT NULL,
            source TEXT NOT NULL DEFAULT 'sensor'
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_readings_timestamp ON readings(timestamp DESC)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE readings ADD COLUMN oxygen REAL');
        }
      },
    );
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
