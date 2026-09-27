import 'package:sqflite/sqflite.dart';

import 'package:sudoku159/database/database_manager.dart';
import 'package:sudoku159/model/daily_challenge_completion_detail.dart';

/// '그 날의' 오늘의 도전 퍼즐을 클리어한 로컬 일자(YYYY-MM-DD)를 저장합니다.
/// (레벨·게임당 1행인 `clear_records`와 달리, 연속 기록용으로 날짜만 누적합니다.)
class DailyChallengeCompletionRepository {
  DailyChallengeCompletionRepository({DatabaseManager? databaseManager})
      : _dbManager = databaseManager ?? DatabaseManager();

  final DatabaseManager _dbManager;

  /// 하루 완료를 기록한다. 같은 날짜가 이미 있으면(재도전) 더 좋은 결과일
  /// 때만 세부 기록을 갱신하고, streak_eligible은 최초 기록 이후로는 절대
  /// 건드리지 않는다(재도전으로 false→true가 되지 않게).
  Future<void> addCompletionForDate(
    String yyyyMmDd, {
    String? levelName,
    int? gameNumber,
    int? clearTime,
    int? wrongCount,
    int? hintsUsed,
    bool autoNotesUsed = false,
    bool streakEligible = true,
  }) async {
    final db = await _dbManager.database;
    final existingRows = await db.query(
      'daily_challenge_completions',
      where: 'completion_date = ?',
      whereArgs: [yyyyMmDd],
      limit: 1,
    );

    final incoming = DailyChallengeCompletionDetail(
      date: yyyyMmDd,
      levelName: levelName,
      gameNumber: gameNumber,
      clearTime: clearTime,
      wrongCount: wrongCount,
      hintsUsed: hintsUsed,
      autoNotesUsed: autoNotesUsed,
      streakEligible: streakEligible,
    );

    if (existingRows.isEmpty) {
      await db.insert(
        'daily_challenge_completions',
        {
          'completion_date': yyyyMmDd,
          'level_name': levelName,
          'game_number': gameNumber,
          'clear_time': clearTime,
          'wrong_count': wrongCount,
          'hints_used': hintsUsed,
          'auto_notes_used': autoNotesUsed ? 1 : 0,
          'streak_eligible': streakEligible ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return;
    }

    final existing = DailyChallengeCompletionDetail.fromRow(existingRows.first);
    if (!existing.isImprovedBy(incoming)) {
      return;
    }
    await db.update(
      'daily_challenge_completions',
      {
        'level_name': levelName,
        'game_number': gameNumber,
        'clear_time': clearTime,
        'wrong_count': wrongCount,
        'hints_used': hintsUsed,
        'auto_notes_used': autoNotesUsed ? 1 : 0,
        // streak_eligible은 의도적으로 갱신하지 않는다.
      },
      where: 'completion_date = ?',
      whereArgs: [yyyyMmDd],
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

  /// 연속 일수 계산 전용: streak_eligible = true인 날짜만 내림차순으로.
  Future<List<String>> getStreakEligibleDatesDescending({
    int limit = 400,
  }) async {
    final db = await _dbManager.database;
    final rows = await db.query(
      'daily_challenge_completions',
      columns: ['completion_date'],
      where: 'streak_eligible = 1',
      orderBy: 'completion_date DESC',
      limit: limit,
    );
    return rows
        .map((row) => row['completion_date']! as String)
        .toList(growable: false);
  }

  /// 지정한 달(YYYY-MM)의 완료 세부 기록을 날짜별로 한 번에 조회한다.
  Future<Map<String, DailyChallengeCompletionDetail>> getCompletionsForMonth(
    int year,
    int month,
  ) async {
    final db = await _dbManager.database;
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await db.query(
      'daily_challenge_completions',
      where: "completion_date LIKE ?",
      whereArgs: ['$prefix%'],
    );
    return {
      for (final row in rows)
        row['completion_date'] as String:
            DailyChallengeCompletionDetail.fromRow(row),
    };
  }

  Future<void> clearAll() async {
    final db = await _dbManager.database;
    await db.delete('daily_challenge_completions');
  }
}
