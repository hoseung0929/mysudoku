import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/level_progress_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('LevelProgressService', () {
    test('refreshes cleared game count for a level', () async {
      final level = SudokuLevel(
        name: '초급',
        description: 'test',
        difficulty: 1,
        emptyCells: 30,
        gameCount: 100,
      );
      final service = LevelProgressService(
        loadClearedGameCount: (levelName) async => levelName == '초급' ? 12 : 0,
      );

      await service.refreshLevel(level);

      expect(level.clearedGames, 12);
    });

    test('falls back to zero when loading cleared count fails', () async {
      final service = LevelProgressService(
        loadClearedGameCount: (_) async => throw Exception('load failed'),
      );

      final count = await service.loadClearedGameCount('초급');

      expect(count, 0);
    });

    test('resets level progress', () async {
      final level = SudokuLevel(
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

      await service.resetLevel(level);

      expect(clearedLevelName, '초급');
      expect(level.clearedGames, 0);
    });
  });
}
