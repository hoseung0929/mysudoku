import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/utils/board_codec.dart';
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

    test('saves and loads extended session state', () async {
      const levelName = '중급';
      const gameNumber = 12;
      final board = List.generate(
        9,
        (row) => List.generate(9, (col) => (row + col) % 9),
      );
      final notes = List.generate(
        9,
        (row) => List.generate(
          9,
          (col) => row == 0 && col == 1 ? <int>{2, 4, 7} : <int>{},
        ),
      );

      await service.saveSession(
        levelName: levelName,
        gameNumber: gameNumber,
        board: board,
        notes: notes,
        elapsedSeconds: 185,
        hintsRemaining: 2,
        wrongCount: 1,
        isMemoMode: true,
        hintCells: const {'0,2'},
        isGameComplete: false,
        isGameOver: false,
      );

      final restored = await service.loadSession(
        levelName: levelName,
        gameNumber: gameNumber,
      );

      expect(restored, isNotNull);
      expect(restored!.board, board);
      expect(restored.notes[0][1], equals({2, 4, 7}));
      expect(restored.elapsedSeconds, 185);
      expect(restored.hintsRemaining, 2);
      expect(restored.wrongCount, 1);
      expect(restored.isMemoMode, isTrue);
      expect(restored.hintCells, equals({'0,2'}));
      expect(restored.isGameComplete, isFalse);
      expect(restored.isGameOver, isFalse);
    });

    test('loads terminal session flags when present', () async {
      const levelName = '전문가';
      const gameNumber = 5;
      final board = List.generate(
        9,
        (row) => List.generate(9, (col) => ((row * 3) + col) % 9 + 1),
      );

      await service.saveSession(
        levelName: levelName,
        gameNumber: gameNumber,
        board: board,
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
        elapsedSeconds: 320,
        hintsRemaining: 0,
        wrongCount: 3,
        isMemoMode: false,
        isGameComplete: false,
        isGameOver: true,
      );

      final restored = await service.loadSession(
        levelName: levelName,
        gameNumber: gameNumber,
      );

      expect(restored, isNotNull);
      expect(restored!.isGameComplete, isFalse);
      expect(restored.isGameOver, isTrue);
    });

    test('loads legacy board-only saves as default session state', () async {
      const levelName = '고급';
      const gameNumber = 3;
      final board =
          List.generate(9, (row) => List.generate(9, (col) => (row * col) % 9));

      SharedPreferences.setMockInitialValues({
        'game_${levelName}_$gameNumber': BoardCodec.encode(board),
      });
      service = GameStateService();

      final restored = await service.loadSession(
        levelName: levelName,
        gameNumber: gameNumber,
      );

      expect(restored, isNotNull);
      expect(restored!.board, board);
      expect(restored.notes.expand((row) => row).every((cell) => cell.isEmpty), isTrue);
      expect(restored.elapsedSeconds, 0);
      expect(restored.hintsRemaining, 3);
      expect(restored.wrongCount, 0);
      expect(restored.isMemoMode, isFalse);
      expect(restored.hintCells, isEmpty);
      expect(restored.isGameComplete, isFalse);
      expect(restored.isGameOver, isFalse);
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
