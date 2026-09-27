import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sudoku159/database/daily_challenge_completion_repository.dart';
import 'package:sudoku159/database/database_manager.dart';
import 'package:sudoku159/model/daily_challenge_completion_detail.dart';

/// 실제 싱글턴(`DatabaseManager`)을 통해 진짜 업그레이드 경로(`onUpgrade`)가
/// 도는지 확인한다. 기존 v7 설치를 그대로 흉내 낸 파일을 먼저 만들어 두고,
/// 그 경로에서 `DatabaseManager().database`를 여는 것만으로 실제 마이그레이션
/// 코드가 실행된다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late String dbPath;
  late Directory originalCwd;
  late Directory isolatedCwd;

  setUpAll(() async {
    // 다른 DB 테스트 파일과 같은 고정 경로(.dart_tool/sqflite_common_ffi/
    // databases/sudoku_games.db)를 두고 병렬로 경합하지 않도록 이 파일만의
    // 임시 작업 디렉터리로 옮긴다.
    originalCwd = Directory.current;
    isolatedCwd = await Directory.systemTemp.createTemp(
      'database_manager_upgrade_test_',
    );
    Directory.current = isolatedCwd;
  });

  tearDownAll(() async {
    Directory.current = originalCwd;
    try {
      await isolatedCwd.delete(recursive: true);
    } catch (_) {}
  });

  Future<void> seedLegacyV7Database() async {
    final legacy = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 7,
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
              UNIQUE(level_name, game_number)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS daily_challenge_completions(
              completion_date TEXT PRIMARY KEY NOT NULL
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
              hints_used INTEGER NOT NULL DEFAULT 0
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
    await legacy.insert('clear_records', {
      'level_name': '초급',
      'game_number': 1,
      'clear_time': 120,
      'wrong_count': 0,
      'clear_date': '2026-01-01',
      'hints_used': 1,
    });
    await legacy.insert('clear_events', {
      'level_name': '초급',
      'game_number': 1,
      'clear_time': 120,
      'wrong_count': 0,
      'clear_date': '2026-01-01',
      'hints_used': 1,
    });
    await legacy.insert('app_metadata', {
      'key': 'catalog_source',
      'value': 'local',
    });
    // v9 이전(월간 달력 세부 필드가 생기기 전)의 완료 기록: 날짜만 있다.
    await legacy.insert('daily_challenge_completions', {
      'completion_date': '2026-01-01',
    });
    // 초기 시드/원격 동기화 로직이 돌지 않도록 게임이 이미 있는 것처럼 만든다
    // (이 테스트의 목적은 마이그레이션이지 카탈로그 시딩이 아니다).
    for (final level in ['초급', '중급', '고급', '전문가', '마스터']) {
      await legacy.insert('games', {
        'level_name': level,
        'game_number': 1,
        'board': '[]',
        'solution': '[]',
      });
    }
    await legacy.close();
  }

  setUp(() async {
    final dir = await databaseFactory.getDatabasesPath();
    await Directory(dir).create(recursive: true);
    dbPath = join(dir, 'sudoku_games.db');
    if (File(dbPath).existsSync()) {
      await File(dbPath).delete();
    }
  });

  tearDown(() async {
    if (File(dbPath).existsSync()) {
      try {
        await File(dbPath).delete();
      } catch (_) {}
    }
  });

  test(
      'upgrading a pre-existing v7 install adds auto_notes_used and the v9 monthly-calendar columns, preserving existing data',
      () async {
    await seedLegacyV7Database();

    final db = await DatabaseManager().database;

    final recordColumns = await db.rawQuery(
      "PRAGMA table_info(clear_records)",
    );
    expect(
      recordColumns.any((c) => c['name'] == 'auto_notes_used'),
      isTrue,
      reason: 'clear_records should gain auto_notes_used after upgrade',
    );
    final eventColumns = await db.rawQuery("PRAGMA table_info(clear_events)");
    expect(
      eventColumns.any((c) => c['name'] == 'auto_notes_used'),
      isTrue,
      reason: 'clear_events should gain auto_notes_used after upgrade',
    );

    final existingRecord = await db.query(
      'clear_records',
      where: 'level_name = ? AND game_number = ?',
      whereArgs: ['초급', 1],
    );
    expect(existingRecord, hasLength(1));
    expect(existingRecord.first['auto_notes_used'], 0);

    final existingEvent = await db.query('clear_events');
    expect(existingEvent, hasLength(1));
    expect(existingEvent.first['auto_notes_used'], 0);

    // v9: daily_challenge_completions에 월간 달력 세부 필드가 모두 생겼는지.
    final completionColumns = await db.rawQuery(
      'PRAGMA table_info(daily_challenge_completions)',
    );
    final completionColumnNames =
        completionColumns.map((c) => c['name'] as String).toSet();
    expect(
      completionColumnNames,
      containsAll(const [
        'completion_date',
        'level_name',
        'game_number',
        'clear_time',
        'wrong_count',
        'hints_used',
        'auto_notes_used',
        'streak_eligible',
      ]),
    );

    // 기존(v9 이전) 완료 행은 날짜를 보존하고, 세부 필드는 기본값으로
    // 채워지며(auto_notes_used=0, streak_eligible=1), 세부 기록이 없으므로
    // 완벽 완료로 판단되지 않아야 한다.
    final existingCompletions = await db.query('daily_challenge_completions');
    expect(existingCompletions, hasLength(1));
    final existingCompletion = existingCompletions.first;
    expect(existingCompletion['completion_date'], '2026-01-01');
    expect(existingCompletion['auto_notes_used'], 0);
    expect(existingCompletion['streak_eligible'], 1);
    expect(existingCompletion['wrong_count'], isNull);
    final detail = DailyChallengeCompletionDetail.fromRow(existingCompletion);
    expect(detail.isPerfect, isFalse);
    expect(detail.streakEligible, isTrue);

    // 월간 완료 배치 조회에도 기존 날짜가 정상적으로 포함되는지(실제
    // 리포지토리를 통해, 같은 싱글턴 연결로).
    final repo = DailyChallengeCompletionRepository(
      databaseManager: DatabaseManager(),
    );
    final januaryCompletions = await repo.getCompletionsForMonth(2026, 1);
    expect(januaryCompletions.keys, contains('2026-01-01'));
    expect(januaryCompletions['2026-01-01']!.streakEligible, isTrue);
  });
}
