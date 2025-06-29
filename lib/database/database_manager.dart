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
    print('=== 게임 데이터 생성 시작 ===');
    int totalGames = 0;
    int iMax = 0; // 개발용 버전으로 100개만 생성\
    int levelGroup = 0;

    for (var level in SudokuLevel.levels) {
      print('${level.name} 레벨 게임 생성 중... (${iMax}개)');

      if (level.name == '마스터') {
        iMax = 100;
      } else {
        iMax = 100;
      }

      totalGames += iMax;

      // 각 레벨별로 설정된 게임 수만큼 게임 데이터 생성
      for (var i = 0; i < iMax; i++) {
        // 실제 스도쿠 게임 데이터 생성
        final board = SudokuGenerator.generateSudoku(level.emptyCells);
        final solution = SudokuGenerator.getSolution(board);

        final boardStr = board.map((row) => row.join(',')).join(';');
        final solutionStr = solution.map((row) => row.join(',')).join(';');

        // 10개의 게임마다 levelGroup 1씩 증가
        levelGroup = (i / 10).floor();
        final levelGroupStr = '${level.name}_$levelGroup';

        await db.insert(
          'games',
          {
            'level_name': level.name,
            'game_number': i + 1,
            'level_group': levelGroupStr,
            'board': boardStr,
            'solution': solutionStr,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 진행 상황 로그 (100개마다 출력)
        if ((i + 1) % 100 == 0) {
          print('  ${level.name} 레벨: ${i + 1}/${iMax} 완료');
        }
      }
      print('${level.name} 레벨 완료! (${iMax}개 생성됨)');
    }

    print('=== 게임 데이터 생성 완료 ===');
    print('총 ${totalGames}개의 게임이 생성되었습니다.');
    print('========================');
  }

  /// 데이터베이스 연결을 닫습니다.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

/// DB 경로를 출력하는 함수
void printDbPath() async {
  try {
    String dbPath = join(await getDatabasesPath(), 'sudoku_games.db');
    print('=== DB 경로 정보 ===');
    print('DB 파일명: sudoku_games.db');
    print('DB 전체 경로: $dbPath');
    print('==================');
  } catch (e) {
    print('DB 경로 출력 중 오류: $e');
  }
}
