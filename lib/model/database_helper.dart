import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sudoku.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE games(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level TEXT NOT NULL,
        board TEXT NOT NULL,
        solution TEXT NOT NULL,
        empty_cells INTEGER NOT NULL,
        game_number INTEGER NOT NULL
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getGames(String level) async {
    final db = await database;
    return await db.query(
      'games',
      where: 'level = ?',
      whereArgs: [level],
    );
  }

  Future<void> insertGame(Map<String, dynamic> game) async {
    final db = await database;
    await db.insert('games', game);
  }

  Future<void> deleteAllGames() async {
    final db = await database;
    await db.delete('games');
  }
}
