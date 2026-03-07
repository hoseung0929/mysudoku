import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/sudoku_level.dart';
import '../utils/sudoku_generator.dart';

/// 데이터베이스 초기화와 기본 관리를 담당하는 클래스
class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  static Database? _database;

  factory DatabaseManager() => _instance;

  DatabaseManager._internal();

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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // 클리어 기록 테이블 생성
    await db.execute('''
      CREATE TABLE clear_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level_name TEXT NOT NULL,
        game_number INTEGER NOT NULL,
        clear_time INTEGER NOT NULL,
        wrong_count INTEGER NOT NULL,
        clear_date TEXT NOT NULL,
        UNIQUE(level_name, game_number)
      )
    ''');

    // 초기 게임 데이터 삽입
    await _insertInitialGames(db);
  }

  /// 데이터베이스 업그레이드 처리
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 클리어 기록 테이블 추가
      await db.execute('''
        CREATE TABLE clear_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          level_name TEXT NOT NULL,
          game_number INTEGER NOT NULL,
          clear_time INTEGER NOT NULL,
          wrong_count INTEGER NOT NULL,
          clear_date TEXT NOT NULL,
          UNIQUE(level_name, game_number)
        )
      ''');
    }
  }

  /// 초기 게임 데이터를 생성하여 데이터베이스에 삽입합니다.
  Future<void> _insertInitialGames(Database db) async {
    if (kDebugMode) {
      print('=== 게임 데이터 생성 시작 ===');
    }
    int totalGames = 0;
    const iMax = 100;

    for (var level in SudokuLevel.levels) {
      if (kDebugMode) {
        print('${level.name} 레벨 게임 생성 중... ($iMax개)');
      }
      totalGames += iMax;

      for (var i = 0; i < iMax; i++) {
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

        if (kDebugMode && (i + 1) % 100 == 0) {
          debugPrint('  ${level.name} 레벨: ${i + 1}/$iMax 완료');
        }
      }
      if (kDebugMode) {
        print('${level.name} 레벨 완료! ($iMax개 생성됨)');
      }
    }

    if (kDebugMode) {
      print('=== 게임 데이터 생성 완료 ===');
      print('총 $totalGames개의 게임이 생성되었습니다.');
      print('========================');
    }
  }

  /// 데이터베이스 연결을 닫습니다.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
