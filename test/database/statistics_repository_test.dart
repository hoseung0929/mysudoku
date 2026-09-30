import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sudoku159/database/clear_record_repository.dart';
import 'package:sudoku159/database/database_manager.dart';
import 'package:sudoku159/database/statistics_repository.dart';

/// DatabaseManager는 싱글턴(연결을 캐시)이라 파일마다 한 번만 초기화하고,
/// 테스트끼리는 서로 다른 레벨·게임 번호를 써서 데이터가 섞이지 않게 한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late StatisticsRepository statisticsRepository;
  late ClearRecordRepository clearRecordRepository;
  late Directory originalCwd;
  late Directory isolatedCwd;

  setUpAll(() async {
    originalCwd = Directory.current;
    isolatedCwd = await Directory.systemTemp.createTemp(
      'statistics_repository_test_',
    );
    Directory.current = isolatedCwd;

    final dir = await databaseFactory.getDatabasesPath();
    await Directory(dir).create(recursive: true);
    final dbPath = join(dir, 'sudoku_games.db');
    if (File(dbPath).existsSync()) {
      await File(dbPath).delete();
    }
    final seedDb = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 9,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS games(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              level_name TEXT NOT NULL,
              game_number INTEGER NOT NULL,
              board TEXT NOT NULL,
              solution TEXT NOT NULL,
              UNIQUE(level_name, game_number)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS clear_records(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              level_name TEXT NOT NULL,
              game_number INTEGER NOT NULL,
              clear_time INTEGER NOT NULL,
              wrong_count INTEGER NOT NULL,
              clear_date TEXT NOT NULL,
              hints_used INTEGER NOT NULL DEFAULT 0,
              auto_notes_used INTEGER NOT NULL DEFAULT 0,
              UNIQUE(level_name, game_number)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS clear_events(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              level_name TEXT NOT NULL,
              game_number INTEGER NOT NULL,
              clear_time INTEGER NOT NULL,
              wrong_count INTEGER NOT NULL,
              clear_date TEXT NOT NULL,
              hints_used INTEGER NOT NULL DEFAULT 0,
              auto_notes_used INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS daily_challenge_completions(
              completion_date TEXT PRIMARY KEY NOT NULL,
              level_name TEXT,
              game_number INTEGER,
              clear_time INTEGER,
              wrong_count INTEGER,
              hints_used INTEGER,
              auto_notes_used INTEGER NOT NULL DEFAULT 0,
              streak_eligible INTEGER NOT NULL DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_metadata(
              key TEXT PRIMARY KEY NOT NULL,
              value TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    for (final level in ['초급', '중급', '고급', '전문가', '마스터']) {
      for (var n = 1; n <= 5; n++) {
        await seedDb.insert('games', {
          'level_name': level,
          'game_number': n,
          'board': '[]',
          'solution': '[]',
        });
      }
    }
    await seedDb.insert('app_metadata', {
      'key': 'catalog_source',
      'value': 'local',
    });
    await seedDb.close();

    statisticsRepository = StatisticsRepository();
    clearRecordRepository = ClearRecordRepository();
    // 싱글턴을 한 번 열어 카탈로그 시딩/백그라운드 보충이 끝나게 한다.
    await DatabaseManager().database;
  });

  tearDownAll(() async {
    Directory.current = originalCwd;
    try {
      await isolatedCwd.delete(recursive: true);
    } catch (_) {}
  });

  /// saveClearRecord(최고 기록, 덮어쓰기)와 saveClearEvent(전체 이력, 누적)를
  /// 실제 게임 흐름처럼 함께 저장한다.
  Future<void> clear({
    required String level,
    required int gameNumber,
    required int clearTime,
    required int wrongCount,
  }) async {
    await clearRecordRepository.saveClearRecord(
      levelName: level,
      gameNumber: gameNumber,
      clearTime: clearTime,
      wrongCount: wrongCount,
      hintsUsed: 0,
    );
    await clearRecordRepository.saveClearEvent(
      levelName: level,
      gameNumber: gameNumber,
      clearTime: clearTime,
      wrongCount: wrongCount,
      hintsUsed: 0,
    );
  }

  test(
    'perfect_clears counts a puzzle once cleared without mistakes, '
    'even after a faster imperfect retry overwrites its best record',
    () async {
      await clear(level: '초급', gameNumber: 1, clearTime: 200, wrongCount: 0);
      var overall = await statisticsRepository.getOverallStatistics();
      expect(overall['perfect_clears'], 1);

      // 더 빠르지만 오답이 있는 재시도가 clear_records의 최고 기록을 덮어써도
      // clear_events에는 무오답 이력이 남아 있어 집계가 줄지 않아야 한다.
      await clear(level: '초급', gameNumber: 1, clearTime: 50, wrongCount: 3);
      overall = await statisticsRepository.getOverallStatistics();
      expect(overall['perfect_clears'], 1);
    },
  );

  test('perfect_clears counts each puzzle at most once', () async {
    final before = (await statisticsRepository
        .getOverallStatistics())['perfect_clears'] as int;
    await clear(level: '중급', gameNumber: 1, clearTime: 100, wrongCount: 0);
    await clear(level: '중급', gameNumber: 1, clearTime: 90, wrongCount: 0);
    await clear(level: '중급', gameNumber: 2, clearTime: 80, wrongCount: 0);

    final after = (await statisticsRepository
        .getOverallStatistics())['perfect_clears'] as int;
    // 서로 다른 퍼즐 두 개(게임 1, 2)를 무오답으로 클리어했으므로 +2여야
    // 하고, 게임 1의 반복 무오답 완료는 두 번 세지 않는다.
    expect(after, before + 2);
  });

  test('a puzzle cleared only with mistakes is not counted as perfect',
      () async {
    final before = (await statisticsRepository
        .getOverallStatistics())['perfect_clears'] as int;
    await clear(level: '고급', gameNumber: 1, clearTime: 300, wrongCount: 2);
    final after = (await statisticsRepository
        .getOverallStatistics())['perfect_clears'] as int;
    expect(after, before);
  });
}
