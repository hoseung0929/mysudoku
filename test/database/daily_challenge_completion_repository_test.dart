import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sudoku159/database/daily_challenge_completion_repository.dart';
import 'package:sudoku159/database/database_manager.dart';

/// DatabaseManager는 싱글턴(연결을 캐시)이라 파일마다 한 번만 초기화하고,
/// 테스트끼리는 서로 다른 날짜 키를 써서 데이터가 섞이지 않게 한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DailyChallengeCompletionRepository repo;
  late Directory originalCwd;
  late Directory isolatedCwd;

  setUpAll(() async {
    // sqflite_common_ffi의 기본 DB 경로는 현재 작업 디렉터리 기준 고정 경로라,
    // 전체 스위트를 병렬로 돌리면 다른 DB 테스트 파일과 같은 파일을 두고
    // 경합한다(database is locked). 이 파일만 쓰는 임시 디렉터리로 옮겨 피한다.
    originalCwd = Directory.current;
    isolatedCwd = await Directory.systemTemp.createTemp(
      'daily_challenge_completion_repository_test_',
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
      for (var n = 1; n <= 3; n++) {
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
    repo = DailyChallengeCompletionRepository(
      databaseManager: DatabaseManager(),
    );
    // 싱글턴을 한 번 열어 카탈로그 시딩/백그라운드 보충이 끝나게 한다.
    await DatabaseManager().database;
  });

  tearDownAll(() async {
    Directory.current = originalCwd;
    try {
      await isolatedCwd.delete(recursive: true);
    } catch (_) {}
  });

  test('a first completion is stored with its detail as given', () async {
    await repo.addCompletionForDate(
      '2026-01-05',
      levelName: '초급',
      gameNumber: 3,
      clearTime: 200,
      wrongCount: 1,
      hintsUsed: 1,
      streakEligible: true,
    );
    final month = await repo.getCompletionsForMonth(2026, 1);
    final detail = month['2026-01-05']!;
    expect(detail.levelName, '초급');
    expect(detail.gameNumber, 3);
    expect(detail.wrongCount, 1);
    expect(detail.streakEligible, isTrue);
  });

  test('a worse retry does not overwrite the existing detail', () async {
    await repo.addCompletionForDate(
      '2026-01-06',
      wrongCount: 0,
      hintsUsed: 0,
      clearTime: 100,
    );
    await repo.addCompletionForDate(
      '2026-01-06',
      wrongCount: 2,
      hintsUsed: 0,
      clearTime: 50,
    );
    final month = await repo.getCompletionsForMonth(2026, 1);
    expect(month['2026-01-06']!.wrongCount, 0);
  });

  test('a better retry (fewer mistakes) overwrites the detail', () async {
    await repo.addCompletionForDate(
      '2026-01-07',
      wrongCount: 2,
      hintsUsed: 1,
      clearTime: 300,
    );
    await repo.addCompletionForDate(
      '2026-01-07',
      wrongCount: 0,
      hintsUsed: 1,
      clearTime: 300,
    );
    final month = await repo.getCompletionsForMonth(2026, 1);
    expect(month['2026-01-07']!.wrongCount, 0);
  });

  test('fewer hints wins a tie on mistakes', () async {
    await repo.addCompletionForDate(
      '2026-01-08',
      wrongCount: 1,
      hintsUsed: 2,
      clearTime: 300,
    );
    await repo.addCompletionForDate(
      '2026-01-08',
      wrongCount: 1,
      hintsUsed: 0,
      clearTime: 300,
    );
    final month = await repo.getCompletionsForMonth(2026, 1);
    expect(month['2026-01-08']!.hintsUsed, 0);
  });

  test(
      'a retry never promotes streak_eligible from false to true, and does not add a new row',
      () async {
    await repo.addCompletionForDate(
      '2026-01-09',
      wrongCount: 3,
      streakEligible: false,
    );
    await repo.addCompletionForDate(
      '2026-01-09',
      wrongCount: 0,
      streakEligible: true,
    );
    final month = await repo.getCompletionsForMonth(2026, 1);
    expect(month['2026-01-09']!.wrongCount, 0);
    expect(month['2026-01-09']!.streakEligible, isFalse);
  });

  test('streak-eligible-only listing excludes ineligible dates', () async {
    await repo.addCompletionForDate('2026-01-10', streakEligible: true);
    await repo.addCompletionForDate('2026-01-11', streakEligible: false);
    final eligible = await repo.getStreakEligibleDatesDescending();
    expect(eligible, contains('2026-01-10'));
    expect(eligible, isNot(contains('2026-01-11')));
    final all = await repo.getCompletionDatesDescending();
    expect(all, containsAll(['2026-01-10', '2026-01-11']));
  });

  test('getCompletionsForMonth only returns rows within that month', () async {
    await repo.addCompletionForDate('2026-03-31');
    await repo.addCompletionForDate('2026-04-01');
    final mar = await repo.getCompletionsForMonth(2026, 3);
    expect(mar.keys, contains('2026-03-31'));
    expect(mar.keys, isNot(contains('2026-04-01')));
    final apr = await repo.getCompletionsForMonth(2026, 4);
    expect(apr.keys, contains('2026-04-01'));
    expect(apr.keys, isNot(contains('2026-03-31')));
  });
}
