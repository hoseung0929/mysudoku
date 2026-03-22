import 'package:flutter/foundation.dart';

import 'package:mysudoku/utils/app_logger.dart';
import '../database/database_helper.dart';

class GameRecordService {
  GameRecordService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  Future<bool> saveClearRecordIfBest({
    required String levelName,
    required int gameNumber,
    required int clearTime,
    required int wrongCount,
  }) async {
    try {
      final existing =
          await _databaseHelper.getClearRecord(levelName, gameNumber);
      final isNewBestRecord = existing == null ||
          clearTime < (existing['clear_time'] as int) ||
          (clearTime == (existing['clear_time'] as int) &&
              wrongCount < (existing['wrong_count'] as int));

      await _databaseHelper.saveClearRecord(
        levelName: levelName,
        gameNumber: gameNumber,
        clearTime: clearTime,
        wrongCount: wrongCount,
      );

      if (kDebugMode) {
        AppLogger.debug('클리어 기록 저장 완료: $levelName 게임 $gameNumber');
      }

      return isNewBestRecord;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('클리어 기록 저장 실패: $e');
      }
      return false;
    }
  }
}
