import 'package:flutter/foundation.dart';

import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/database/database_helper.dart';

class GameRecordService {
  GameRecordService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  /// 첫 완료이거나 이전 최고 기록보다 좋으면 저장한다.
  /// [improvedPrevious]는 기존 기록을 넘어섰을 때만 true다. 첫 완료는 비교할
  /// 기록이 없으므로 "새 최고 기록"으로 알리지 않는다.
  Future<({bool saved, bool improvedPrevious})> saveClearRecordIfBest({
    required String levelName,
    required int gameNumber,
    required int clearTime,
    required int wrongCount,
    required int hintsUsed,
    bool autoNotesUsed = false,
  }) async {
    try {
      final existing =
          await _databaseHelper.getClearRecord(levelName, gameNumber);
      final improvedPrevious = existing != null &&
          isBetterThan(
            existing,
            clearTime: clearTime,
            wrongCount: wrongCount,
          );
      final shouldSave = existing == null || improvedPrevious;

      if (shouldSave) {
        await _databaseHelper.saveClearRecord(
          levelName: levelName,
          gameNumber: gameNumber,
          clearTime: clearTime,
          wrongCount: wrongCount,
          hintsUsed: hintsUsed,
          autoNotesUsed: autoNotesUsed,
        );
        if (kDebugMode) {
          AppLogger.debug('클리어 기록 저장 완료: $levelName 게임 $gameNumber');
        }
      }

      return (saved: shouldSave, improvedPrevious: improvedPrevious);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('클리어 기록 저장 실패: $e');
      }
      return (saved: false, improvedPrevious: false);
    }
  }

  /// 시간이 더 짧거나, 같은 시간에 오답이 더 적으면 더 좋은 기록이다.
  static bool isBetterThan(
    Map<String, dynamic> existing, {
    required int clearTime,
    required int wrongCount,
  }) {
    final bestTime = existing['clear_time'] as int;
    return clearTime < bestTime ||
        (clearTime == bestTime &&
            wrongCount < (existing['wrong_count'] as int));
  }
}
