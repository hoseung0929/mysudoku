// ignore_for_file: avoid_print
//
// 퍼즐 초기 DB 생성 스크립트
// 실행: dart run tool/generate_db.dart
//
// assets/initial_puzzles.db 파일을 생성합니다.
// sqflite_common_ffi 패키지가 dev_dependencies에 있어야 합니다.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/utils/board_codec.dart';
import 'package:sudoku159/utils/sudoku_generator.dart';

const int _gamesPerLevel = 159;
const int _masterGamesCount = 20;

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final outputPath =
      p.join(Directory.current.path, 'assets', 'initial_puzzles.db');

  final file = File(outputPath);
  if (file.existsSync()) {
    file.deleteSync();
    print('기존 DB 삭제');
  }

  final db = await databaseFactoryFfi.openDatabase(outputPath);

  // 테이블 생성 (앱 DB 스키마와 동일)
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

  await db.execute('''
    CREATE TABLE daily_challenge_completions(
      completion_date TEXT PRIMARY KEY NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE clear_events(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      level_name TEXT NOT NULL,
      game_number INTEGER NOT NULL,
      clear_time INTEGER NOT NULL,
      wrong_count INTEGER NOT NULL,
      clear_date TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE app_metadata(
      key TEXT PRIMARY KEY NOT NULL,
      value TEXT NOT NULL
    )
  ''');

  // catalog_source = local 설정
  await db.insert('app_metadata', {
    'key': 'catalog_source',
    'value': 'local',
  });

  // sqflite DB 버전을 6으로 설정
  // → 앱이 열 때 onCreate/onUpgrade 미호출, onOpen만 호출됨
  await db.execute('PRAGMA user_version = 6');

  int total = 0;
  final totalStopwatch = Stopwatch()..start();

  for (final level in SudokuLevel.levels) {
    final count = level.name == '마스터' ? _masterGamesCount : _gamesPerLevel;
    final levelStopwatch = Stopwatch()..start();
    print('\n[${level.name}] $count개 생성 시작 (빈칸: ${level.emptyCells})');

    for (int i = 1; i <= count; i++) {
      List<List<int>>? board;
      while (board == null) {
        board = SudokuGenerator.tryGenerateSudoku(level.emptyCells);
      }
      final solution = SudokuGenerator.getSolution(board);
      await db.insert('games', {
        'level_name': level.name,
        'game_number': i,
        'board': BoardCodec.encode(board),
        'solution': BoardCodec.encode(solution),
      });
      total++;
      if (i % 20 == 0 || i == count) {
        print('  $i/$_gamesPerLevel 완료');
      }
    }

    levelStopwatch.stop();
    print('[${level.name}] 완료 (${levelStopwatch.elapsed.inSeconds}초)');
  }

  await db.close();

  totalStopwatch.stop();
  final sizeKb = file.lengthSync() ~/ 1024;
  print('\n생성 완료: 총 $total개, ${sizeKb}KB, 소요시간: ${totalStopwatch.elapsed.inSeconds}초');
  print('저장 위치: $outputPath');
}
