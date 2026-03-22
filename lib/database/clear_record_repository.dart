import 'package:flutter/foundation.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';
import 'database_manager.dart';

/// 클리어 기록 관리를 담당하는 클래스
class ClearRecordRepository {
  final DatabaseManager _dbManager = DatabaseManager();

  /// 클리어 기록을 저장합니다.
  Future<void> saveClearRecord({
    required String levelName,
    required int gameNumber,
    required int clearTime,
    required int wrongCount,
  }) async {
    final db = await _dbManager.database;
    final now = DateTime.now();
    final clearDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await db.insert(
      'clear_records',
      {
        'level_name': levelName,
        'game_number': gameNumber,
        'clear_time': clearTime,
        'wrong_count': wrongCount,
        'clear_date': clearDate,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (kDebugMode) {
      AppLogger.debug(
        '클리어 기록 저장: $levelName 게임 $gameNumber, $clearTime초, 오답 $wrongCount개',
      );
    }
  }

  /// 특정 레벨의 클리어 기록을 조회합니다.
  Future<List<Map<String, dynamic>>> getClearRecordsForLevel(
      String levelName) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clear_records',
      where: 'level_name = ?',
      whereArgs: [levelName],
      orderBy: 'clear_date DESC, clear_time ASC',
    );

    return maps;
  }

  /// 특정 게임의 클리어 기록을 조회합니다.
  Future<Map<String, dynamic>?> getClearRecord(
      String levelName, int gameNumber) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clear_records',
      where: 'level_name = ? AND game_number = ?',
      whereArgs: [levelName, gameNumber],
    );

    return maps.isNotEmpty ? maps.first : null;
  }

  /// 특정 레벨의 클리어된 게임 수를 반환합니다.
  Future<int> getClearedGameCount(String levelName) async {
    final db = await _dbManager.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clear_records WHERE level_name = ?',
      [levelName],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 특정 레벨의 최고 기록을 반환합니다.
  Future<Map<String, dynamic>?> getBestRecord(String levelName) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clear_records',
      where: 'level_name = ?',
      whereArgs: [levelName],
      orderBy: 'clear_time ASC, wrong_count ASC',
      limit: 1,
    );

    return maps.isNotEmpty ? maps.first : null;
  }

  /// 특정 레벨의 평균 클리어 시간을 반환합니다.
  Future<double> getAverageClearTime(String levelName) async {
    final db = await _dbManager.database;
    final result = await db.rawQuery(
      'SELECT AVG(clear_time) as avg_time FROM clear_records WHERE level_name = ?',
      [levelName],
    );

    return (result.first['avg_time'] as num?)?.toDouble() ?? 0.0;
  }

  /// 특정 레벨의 평균 오답 수를 반환합니다.
  Future<double> getAverageWrongCount(String levelName) async {
    final db = await _dbManager.database;
    final result = await db.rawQuery(
      'SELECT AVG(wrong_count) as avg_wrong FROM clear_records WHERE level_name = ?',
      [levelName],
    );

    return (result.first['avg_wrong'] as num?)?.toDouble() ?? 0.0;
  }

  /// 모든 클리어 기록을 삭제합니다.
  Future<void> clearAllRecords() async {
    final db = await _dbManager.database;
    await db.delete('clear_records');
    if (kDebugMode) {
      AppLogger.debug('모든 클리어 기록 삭제 완료');
    }
  }

  /// 특정 레벨의 클리어 기록을 삭제합니다.
  Future<void> clearRecordsForLevel(String levelName) async {
    final db = await _dbManager.database;
    await db.delete(
      'clear_records',
      where: 'level_name = ?',
      whereArgs: [levelName],
    );
    if (kDebugMode) {
      AppLogger.debug('$levelName 레벨의 클리어 기록 삭제 완료');
    }
  }

  /// 특정 게임의 클리어 기록을 삭제합니다.
  Future<void> clearRecord(String levelName, int gameNumber) async {
    final db = await _dbManager.database;
    await db.delete(
      'clear_records',
      where: 'level_name = ? AND game_number = ?',
      whereArgs: [levelName, gameNumber],
    );
    if (kDebugMode) {
      AppLogger.debug('$levelName 게임 $gameNumber의 클리어 기록 삭제 완료');
    }
  }
}
