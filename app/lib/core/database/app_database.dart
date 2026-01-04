import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'deadline_tracker.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // TASKS
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            startAt INTEGER,
            dueAt INTEGER,
            priority INTEGER,
            progress INTEGER,
            status INTEGER,
            createdAt INTEGER,
            updatedAt INTEGER
          )
        ''');

        // REMINDERS
        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            taskId INTEGER NOT NULL,
            remindAt INTEGER NOT NULL,
            FOREIGN KEY (taskId) REFERENCES tasks(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }
}
