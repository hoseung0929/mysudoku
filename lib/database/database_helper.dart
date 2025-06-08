import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/sudoku_level.dart';
import '../utils/sudoku_generator.dart';

/// SQLite 데이터베이스를 관리하는 헬퍼 클래스
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// 데이터베이스 인스턴스를 반환합니다.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 데이터베이스를 초기화합니다.
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sudoku_games.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        // 데이터베이스가 비어있는 경우에만 초기 데이터 삽입
        final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM games'));
        if (count == 0) {
          await _insertInitialGames(db);
        }
      },
    );
  }

  /// 데이터베이스 테이블을 생성하고 초기 데이터를 삽입합니다.
  Future<void> _onCreate(Database db, int version) async {
    // 게임 테이블 생성
    await db.execute('''
      CREATE TABLE games(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level_name TEXT NOT NULL,
        game_number INTEGER NOT NULL,
        board TEXT NOT NULL,
        solution TEXT NOT NULL,
        UNIQUE(level_name, game_number)
      )
    ''');

    // 초기 게임 데이터 삽입
    await _insertInitialGames(db);
  }

  /// 초기 게임 데이터를 생성하여 데이터베이스에 삽입합니다.
  Future<void> _insertInitialGames(Database db) async {
    for (var level in SudokuLevel.levels) {
      // 각 레벨별로 30개의 게임 데이터 생성
      for (var i = 0; i < level.gameCount; i++) {
        // 실제 스도쿠 게임 데이터 생성
        final board = SudokuGenerator.generateSudoku(level.emptyCells);
        final solution = SudokuGenerator.getSolution(board);

        final boardStr = board.map((row) => row.join(',')).join(';');
        final solutionStr = solution.map((row) => row.join(',')).join(';');

        await db.insert(
          'games',
          {
            'level_name': level.name,
            'game_number': i + 1,
            'board': boardStr,
            'solution': solutionStr,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  /// 특정 레벨의 모든 게임 데이터를 반환합니다.
  Future<List<List<List<int>>>> getGamesForLevel(String levelName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'level_name = ?',
      whereArgs: [levelName],
      orderBy: 'game_number ASC',
    );

    return maps.map((map) {
      final String boardStr = map['board'] as String;
      return boardStr.split(';').map((row) {
        return row.split(',').map((cell) => int.parse(cell)).toList();
      }).toList();
    }).toList();
  }

  /// 특정 레벨의 특정 게임 데이터를 반환합니다.
  Future<List<List<int>>> getGame(String levelName, int gameNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'level_name = ? AND game_number = ?',
      whereArgs: [levelName, gameNumber],
    );

    if (maps.isEmpty) return [];

    final String boardStr = maps.first['board'] as String;
    return boardStr.split(';').map((row) {
      return row.split(',').map((cell) => int.parse(cell)).toList();
    }).toList();
  }

  /// 특정 레벨의 특정 게임의 해답을 반환합니다.
  Future<List<List<int>>> getSolution(String levelName, int gameNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'level_name = ? AND game_number = ?',
      whereArgs: [levelName, gameNumber],
    );

    if (maps.isEmpty) return [];

    final String solutionStr = maps.first['solution'] as String;
    return solutionStr.split(';').map((row) {
      return row.split(',').map((cell) => int.parse(cell)).toList();
    }).toList();
  }
}
