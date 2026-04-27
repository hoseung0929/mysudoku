import 'package:sqflite/sqflite.dart';
import 'database_manager.dart';

/// 통계 기능을 담당하는 클래스
class StatisticsRepository {
  final DatabaseManager _dbManager = DatabaseManager();

  /// 특정 레벨의 통계 정보를 반환합니다.
  Future<Map<String, dynamic>> getLevelStatistics(String levelName) async {
    final db = await _dbManager.database;

    // 클리어된 게임 수
    final clearedCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clear_records WHERE level_name = ?',
      [levelName],
    );
    final clearedCount = Sqflite.firstIntValue(clearedCountResult) ?? 0;

    // 총 게임 수
    final totalCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM games WHERE level_name = ?',
      [levelName],
    );
    final totalCount = Sqflite.firstIntValue(totalCountResult) ?? 0;

    // 최고 기록
    final bestRecordResult = await db.query(
      'clear_records',
      where: 'level_name = ?',
      whereArgs: [levelName],
      orderBy: 'clear_time ASC, wrong_count ASC',
      limit: 1,
    );

    // 평균 클리어 시간
    final avgTimeResult = await db.rawQuery(
      'SELECT AVG(clear_time) as avg_time FROM clear_records WHERE level_name = ?',
      [levelName],
    );
    final avgTime =
        (avgTimeResult.first['avg_time'] as num?)?.toDouble() ?? 0.0;

    // 평균 오답 수
    final avgWrongResult = await db.rawQuery(
      'SELECT AVG(wrong_count) as avg_wrong FROM clear_records WHERE level_name = ?',
      [levelName],
    );
    final avgWrong =
        (avgWrongResult.first['avg_wrong'] as num?)?.toDouble() ?? 0.0;

    // 클리어율
    final clearRate = totalCount > 0 ? (clearedCount / totalCount) * 100 : 0.0;

    return {
      'level_name': levelName,
      'cleared_count': clearedCount,
      'total_count': totalCount,
      'clear_rate': clearRate,
      'best_record':
          bestRecordResult.isNotEmpty ? bestRecordResult.first : null,
      'average_time': avgTime,
      'average_wrong_count': avgWrong,
    };
  }

  /// 모든 레벨의 통계 정보를 반환합니다.
  Future<List<Map<String, dynamic>>> getAllLevelStatistics() async {
    final levels = ['초급', '중급', '고급', '전문가', '마스터'];
    final statistics = <Map<String, dynamic>>[];

    for (final level in levels) {
      final stat = await getLevelStatistics(level);
      statistics.add(stat);
    }

    return statistics;
  }

  /// 전체 통계 정보를 반환합니다.
  Future<Map<String, dynamic>> getOverallStatistics() async {
    final db = await _dbManager.database;

    // 전체 클리어된 게임 수
    final totalClearedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clear_records',
    );
    final totalCleared = Sqflite.firstIntValue(totalClearedResult) ?? 0;

    // 전체 게임 수
    final totalGamesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM games',
    );
    final totalGames = Sqflite.firstIntValue(totalGamesResult) ?? 0;

    // 전체 평균 클리어 시간
    final totalAvgTimeResult = await db.rawQuery(
      'SELECT AVG(clear_time) as avg_time FROM clear_records',
    );
    final totalAvgTime =
        (totalAvgTimeResult.first['avg_time'] as num?)?.toDouble() ?? 0.0;

    // 전체 평균 오답 수
    final totalAvgWrongResult = await db.rawQuery(
      'SELECT AVG(wrong_count) as avg_wrong FROM clear_records',
    );
    final totalAvgWrong =
        (totalAvgWrongResult.first['avg_wrong'] as num?)?.toDouble() ?? 0.0;

    // 전체 클리어율
    final totalClearRate =
        totalGames > 0 ? (totalCleared / totalGames) * 100 : 0.0;

    return {
      'total_cleared': totalCleared,
      'total_games': totalGames,
      'total_clear_rate': totalClearRate,
      'total_average_time': totalAvgTime,
      'total_average_wrong_count': totalAvgWrong,
    };
  }

  /// 최근 클리어 기록을 반환합니다.
  Future<List<Map<String, dynamic>>> getRecentClearRecords({
    int? limit,
  }) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clear_records',
      orderBy: 'clear_date DESC, clear_time ASC',
      limit: limit,
    );

    return maps;
  }

  /// 특정 기간의 클리어 기록을 반환합니다.
  Future<List<Map<String, dynamic>>> getClearRecordsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clear_records',
      where: 'clear_date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'clear_date DESC, clear_time ASC',
    );

    return maps;
  }
}
