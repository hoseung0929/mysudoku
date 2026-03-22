import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  group('GameStateService', () {
    late GameStateService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = GameStateService();
    });

    test('saves and loads board state', () async {
      const levelName = '초급';
      const gameNumber = 7;
      final board =
          List.generate(9, (row) => List.generate(9, (col) => row + col));

      await service.saveBoard(
        levelName: levelName,
        gameNumber: gameNumber,
        board: board,
      );

      final restored = await service.loadBoard(
        levelName: levelName,
        gameNumber: gameNumber,
      );

      expect(restored, board);
    });

    test('detects incompatible restored board', () {
      final originalBoard = [
        [5, 0, 0],
        [0, 3, 0],
        [0, 0, 7],
      ];
      final restoredBoard = [
        [4, 1, 2],
        [6, 3, 8],
        [9, 5, 7],
      ];

      final isCompatible = service.isBoardCompatible(
        originalBoard: originalBoard,
        restoredBoard: restoredBoard,
      );

      expect(isCompatible, isFalse);
    });
  });
}
