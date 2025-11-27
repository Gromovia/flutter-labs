import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../task_model.dart';  // Убедитесь в правильном пути

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'tasks.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        dueDate TEXT,
        isCompleted INTEGER
      )
    ''');
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));  // Изменено: fromMap вместо fromJson
  }

  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);  // Изменено: fromMap вместо fromJson
    }
    return null;
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);  // Изменено: toMap вместо toJson (для консистентности, но toJson тоже работает, если isCompleted int)
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);  // Изменено: toMap вместо toJson
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks');  // Очистка и перезапись
      for (var task in tasks) {
        await txn.insert('tasks', task.toMap());  // Изменено: toMap вместо toJson
      }
    });
  }
}
