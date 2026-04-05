import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/view/sudoku_game/game_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  group('GameSessionController', () {
    late GameStateService gameStateService;
    late GameSessionController controller;
    late SudokuGame game;
    final level = SudokuLevel.levels.first;
    final puzzleBoard = [
      [5, 0, 0, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ];
    final solution = [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ];

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      gameStateService = GameStateService();
      controller = GameSessionController(gameStateService: gameStateService);
      game = SudokuGame(
        board: puzzleBoard,
        solution: solution,
        emptyCells: level.emptyCells,
        levelName: level.name,
        gameNumber: 7,
      );
    });

    test('restores active saved session when requested', () async {
      final restoredBoard = puzzleBoard.map((row) => List<int>.from(row)).toList();
      restoredBoard[0][1] = 3;

      await gameStateService.saveSession(
        levelName: level.name,
        gameNumber: game.gameNumber,
        board: restoredBoard,
        notes: List.generate(
          9,
          (row) => List.generate(
            9,
            (col) => row == 0 && col == 2 ? <int>{4, 7} : <int>{},
          ),
        ),
        elapsedSeconds: 90,
        hintsRemaining: 2,
        wrongCount: 1,
        isMemoMode: true,
        hintCells: const {'0,1'},
      );

      final bootstrap = await controller.prepareSession(
        game: game,
        level: level,
        restoreSavedSession: true,
      );

      expect(bootstrap.activeSession, isNotNull);
      expect(bootstrap.initialBoard, restoredBoard);
      expect(bootstrap.activeSession!.elapsedSeconds, 90);
      expect(bootstrap.activeSession!.notes[0][2], equals({4, 7}));
    });

    test('starts from puzzle board and clears saved state when not restoring', () async {
      final restoredBoard = puzzleBoard.map((row) => List<int>.from(row)).toList();
      restoredBoard[0][1] = 3;

      await gameStateService.saveSession(
        levelName: level.name,
        gameNumber: game.gameNumber,
        board: restoredBoard,
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
        elapsedSeconds: 45,
        hintsRemaining: 2,
        wrongCount: 0,
        isMemoMode: false,
      );

      final bootstrap = await controller.prepareSession(
        game: game,
        level: level,
        restoreSavedSession: false,
      );

      expect(bootstrap.activeSession, isNull);
      expect(bootstrap.initialBoard, puzzleBoard);
      expect(
        await gameStateService.loadSession(
          levelName: level.name,
          gameNumber: game.gameNumber,
        ),
        isNull,
      );
    });

    test('discards terminal saved sessions before restoring', () async {
      await gameStateService.saveSession(
        levelName: level.name,
        gameNumber: game.gameNumber,
        board: solution,
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
        elapsedSeconds: 320,
        hintsRemaining: 0,
        wrongCount: 3,
        isMemoMode: false,
        isGameOver: true,
      );

      final bootstrap = await controller.prepareSession(
        game: game,
        level: level,
        restoreSavedSession: true,
      );

      expect(bootstrap.activeSession, isNull);
      expect(bootstrap.initialBoard, puzzleBoard);
      expect(
        await gameStateService.loadSession(
          levelName: level.name,
          gameNumber: game.gameNumber,
        ),
        isNull,
      );
    });

    test('clears persisted session when flush receives completed snapshot', () async {
      await gameStateService.saveSession(
        levelName: level.name,
        gameNumber: game.gameNumber,
        board: puzzleBoard,
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
        elapsedSeconds: 10,
        hintsRemaining: 3,
        wrongCount: 0,
        isMemoMode: false,
      );

      await controller.flushSave(
        level: level,
        gameNumber: game.gameNumber,
        snapshot: GameSessionSnapshot(
          board: solution,
          notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
          elapsedSeconds: 120,
          wrongCount: 1,
          isMemoMode: false,
          isGameComplete: true,
          isGameOver: false,
          hintsRemaining: 3,
          hintCells: const {},
        ),
      );

      expect(
        await gameStateService.loadSession(
          levelName: level.name,
          gameNumber: game.gameNumber,
        ),
        isNull,
      );
    });
  });
}
