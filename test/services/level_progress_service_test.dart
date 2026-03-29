import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/level_progress_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('LevelProgressService', () {
    test('refreshes cleared game count for a level', () async {
      const level = SudokuLevel(
        name: '초급',
        description: 'test',
        difficulty: 1,
        emptyCells: 30,
        gameCount: 100,
      );
      final service = LevelProgressService(
        loadClearedGameCount: (levelName) async => levelName == '초급' ? 12 : 0,
      );

      final refreshed = await service.refreshLevel(level);

      expect(refreshed.clearedGames, 12);
      expect(level.clearedGames, 0);
    });

    test('falls back to zero when loading cleared count fails', () async {
      final service = LevelProgressService(
        loadClearedGameCount: (_) async => throw Exception('load failed'),
      );

      final count = await service.loadClearedGameCount('초급');

      expect(count, 0);
    });

    test('resets level progress', () async {
      const level = SudokuLevel(
        name: '초급',
        description: 'test',
        difficulty: 1,
        emptyCells: 30,
        gameCount: 100,
        clearedGames: 5,
      );
      String? clearedLevelName;
      final service = LevelProgressService(
        clearRecordsForLevel: (levelName) async {
          clearedLevelName = levelName;
        },
      );

      final resetLevel = await service.resetLevel(level);

      expect(clearedLevelName, '초급');
      expect(resetLevel.clearedGames, 0);
      expect(level.clearedGames, 5);
    });
  });
}
