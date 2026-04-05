import 'package:sqflite/sqflite.dart';

import 'package:mysudoku/database/database_manager.dart';

/// '그 날의' 오늘의 도전 퍼즐을 클리어한 로컬 일자(YYYY-MM-DD)를 저장합니다.
/// (레벨·게임당 1행인 `clear_records`와 달리, 연속 기록용으로 날짜만 누적합니다.)
class DailyChallengeCompletionRepository {
  DailyChallengeCompletionRepository({DatabaseManager? databaseManager})
      : _dbManager = databaseManager ?? DatabaseManager();

  final DatabaseManager _dbManager;

  Future<void> addCompletionForDate(String yyyyMmDd) async {
    final db = await _dbManager.database;
    await db.insert(
      'daily_challenge_completions',
      {'completion_date': yyyyMmDd},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<bool> hasCompletionForDate(String yyyyMmDd) async {
    final db = await _dbManager.database;
    final rows = await db.query(
      'daily_challenge_completions',
      where: 'completion_date = ?',
      whereArgs: [yyyyMmDd],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<String>> getCompletionDatesDescending({int limit = 400}) async {
    final db = await _dbManager.database;
    final rows = await db.query(
      'daily_challenge_completions',
      columns: ['completion_date'],
      orderBy: 'completion_date DESC',
      limit: limit,
    );
    return rows
        .map((row) => row['completion_date']! as String)
        .toList(growable: false);
  }

  Future<void> clearAll() async {
    final db = await _dbManager.database;
    await db.delete('daily_challenge_completions');
  }
}
