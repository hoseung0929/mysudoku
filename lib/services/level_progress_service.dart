import 'package:flutter/foundation.dart';
import 'package:mysudoku/utils/app_logger.dart';

import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/model/sudoku_level.dart';

typedef ClearedGameCountLoader = Future<int> Function(String levelName);
typedef LevelRecordsClearer = Future<void> Function(String levelName);

class LevelProgressService {
  LevelProgressService({
    DatabaseHelper? databaseHelper,
    ClearedGameCountLoader? loadClearedGameCount,
    LevelRecordsClearer? clearRecordsForLevel,
  })  : _loadClearedGameCount =
            loadClearedGameCount ?? ((levelName) => (databaseHelper ?? DatabaseHelper()).getClearedGameCount(levelName)),
        _clearRecordsForLevel =
            clearRecordsForLevel ?? ((levelName) => (databaseHelper ?? DatabaseHelper()).clearRecordsForLevel(levelName));

  final ClearedGameCountLoader _loadClearedGameCount;
  final LevelRecordsClearer _clearRecordsForLevel;

  Future<int> loadClearedGameCount(String levelName) async {
    try {
      return await _loadClearedGameCount(levelName);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('클리어된 게임 수 로드 실패: $e');
      }
      return 0;
    }
  }

  Future<SudokuLevel> refreshLevel(SudokuLevel level) async {
    final clearedGames = await loadClearedGameCount(level.name);
    return level.copyWith(clearedGames: clearedGames);
  }

  Future<List<SudokuLevel>> refreshAllLevels(List<SudokuLevel> levels) async {
    final refreshedLevels = <SudokuLevel>[];
    for (final level in levels) {
      refreshedLevels.add(await refreshLevel(level));
    }
    return refreshedLevels;
  }

  Future<SudokuLevel> resetLevel(SudokuLevel level) async {
    try {
      await _clearRecordsForLevel(level.name);
      return level.copyWith(clearedGames: 0);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('클리어된 게임 수 초기화 실패: $e');
      }
      return level;
    }
  }
}
