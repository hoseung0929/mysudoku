import 'database_manager.dart';
import 'game_repository.dart';
import 'clear_record_repository.dart';
import 'statistics_repository.dart';

/// SQLite 데이터베이스를 관리하는 헬퍼 클래스
/// 각 Repository를 통합하여 제공하는 Facade 패턴 구현
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  final GameRepository _gameRepository = GameRepository();
  final ClearRecordRepository _clearRecordRepository = ClearRecordRepository();
  final StatisticsRepository _statisticsRepository = StatisticsRepository();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // ========== 게임 데이터 관련 메서드들 ==========

  /// 특정 레벨의 모든 게임 데이터를 반환합니다.
  Future<List<List<List<int>>>> getGamesForLevel(String levelName) async {
    return await _gameRepository.getGamesForLevel(levelName);
  }

  /// 특정 레벨의 게임/해답 데이터를 함께 반환합니다.
  Future<List<Map<String, dynamic>>> getGameEntriesForLevel(
      String levelName) async {
    return await _gameRepository.getGameEntriesForLevel(levelName);
  }

  /// 특정 레벨의 특정 게임 데이터를 반환합니다.
  Future<List<List<int>>> getGame(String levelName, int gameNumber) async {
    return await _gameRepository.getGame(levelName, gameNumber);
  }

  /// 특정 레벨의 특정 게임/해답 데이터를 함께 반환합니다.
  Future<Map<String, dynamic>?> getGameEntry(
    String levelName,
    int gameNumber,
  ) async {
    return await _gameRepository.getGameEntry(levelName, gameNumber);
  }

  /// 특정 레벨의 특정 게임의 해답을 반환합니다.
  Future<List<List<int>>> getSolution(String levelName, int gameNumber) async {
    return await _gameRepository.getSolution(levelName, gameNumber);
  }

  /// 특정 레벨의 게임 수를 반환합니다.
  Future<int> getGameCount(String levelName) async {
    return await _gameRepository.getGameCount(levelName);
  }

  // ========== 클리어 기록 관련 메서드들 ==========

  /// 클리어 기록을 저장합니다.
  Future<void> saveClearRecord({
    required String levelName,
    required int gameNumber,
    required int clearTime,
    required int wrongCount,
  }) async {
    await _clearRecordRepository.saveClearRecord(
      levelName: levelName,
      gameNumber: gameNumber,
      clearTime: clearTime,
      wrongCount: wrongCount,
    );
  }

  /// 특정 레벨의 클리어 기록을 조회합니다.
  Future<List<Map<String, dynamic>>> getClearRecordsForLevel(
      String levelName) async {
    return await _clearRecordRepository.getClearRecordsForLevel(levelName);
  }

  /// 특정 게임의 클리어 기록을 조회합니다.
  Future<Map<String, dynamic>?> getClearRecord(
      String levelName, int gameNumber) async {
    return await _clearRecordRepository.getClearRecord(levelName, gameNumber);
  }

  /// 특정 레벨의 클리어된 게임 수를 반환합니다.
  Future<int> getClearedGameCount(String levelName) async {
    return await _clearRecordRepository.getClearedGameCount(levelName);
  }

  /// 특정 레벨의 최고 기록을 반환합니다.
  Future<Map<String, dynamic>?> getBestRecord(String levelName) async {
    return await _clearRecordRepository.getBestRecord(levelName);
  }

  /// 특정 레벨의 평균 클리어 시간을 반환합니다.
  Future<double> getAverageClearTime(String levelName) async {
    return await _clearRecordRepository.getAverageClearTime(levelName);
  }

  /// 특정 레벨의 평균 오답 수를 반환합니다.
  Future<double> getAverageWrongCount(String levelName) async {
    return await _clearRecordRepository.getAverageWrongCount(levelName);
  }

  /// 모든 클리어 기록을 삭제합니다.
  Future<void> clearAllRecords() async {
    await _clearRecordRepository.clearAllRecords();
  }

  /// 특정 레벨의 클리어 기록을 삭제합니다.
  Future<void> clearRecordsForLevel(String levelName) async {
    await _clearRecordRepository.clearRecordsForLevel(levelName);
  }

  /// 특정 게임의 클리어 기록을 삭제합니다.
  Future<void> clearRecord(String levelName, int gameNumber) async {
    await _clearRecordRepository.clearRecord(levelName, gameNumber);
  }

  // ========== 통계 관련 메서드들 ==========

  /// 특정 레벨의 통계 정보를 반환합니다.
  Future<Map<String, dynamic>> getLevelStatistics(String levelName) async {
    return await _statisticsRepository.getLevelStatistics(levelName);
  }

  /// 모든 레벨의 통계 정보를 반환합니다.
  Future<List<Map<String, dynamic>>> getAllLevelStatistics() async {
    return await _statisticsRepository.getAllLevelStatistics();
  }

  /// 전체 통계 정보를 반환합니다.
  Future<Map<String, dynamic>> getOverallStatistics() async {
    return await _statisticsRepository.getOverallStatistics();
  }

  /// 최근 클리어 기록을 반환합니다.
  Future<List<Map<String, dynamic>>> getRecentClearRecords(
      {int limit = 10}) async {
    return await _statisticsRepository.getRecentClearRecords(limit: limit);
  }

  /// 특정 기간의 클리어 기록을 반환합니다.
  Future<List<Map<String, dynamic>>> getClearRecordsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    return await _statisticsRepository.getClearRecordsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ========== 데이터베이스 관리 메서드들 ==========

  /// 데이터베이스 연결을 닫습니다.
  Future<void> close() async {
    final dbManager = DatabaseManager();
    await dbManager.close();
  }
}
