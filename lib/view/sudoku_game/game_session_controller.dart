import 'dart:async';

import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/game_state_service.dart';

class GameSessionSnapshot {
  const GameSessionSnapshot({
    required this.board,
    required this.notes,
    required this.elapsedSeconds,
    required this.wrongCount,
    required this.isMemoMode,
    required this.isGameComplete,
    required this.isGameOver,
    required this.hintsRemaining,
    required this.hintCells,
  });

  final List<List<int>> board;
  final List<List<Set<int>>> notes;
  final int elapsedSeconds;
  final int wrongCount;
  final bool isMemoMode;
  final bool isGameComplete;
  final bool isGameOver;
  final int hintsRemaining;
  final Set<String> hintCells;
}

class GameSessionBootstrap {
  const GameSessionBootstrap({
    required this.initialBoard,
    required this.activeSession,
  });

  final List<List<int>> initialBoard;
  final GameSessionState? activeSession;
}

class GameSessionController {
  GameSessionController({
    GameStateService? gameStateService,
    this.debounceDuration = const Duration(milliseconds: 800),
  }) : _gameStateService = gameStateService ?? GameStateService();

  final GameStateService _gameStateService;
  final Duration debounceDuration;
  Timer? _saveTimer;

  Future<GameSessionBootstrap> prepareSession({
    required SudokuGame game,
    required SudokuLevel level,
    required bool restoreSavedSession,
  }) async {
    final restoredSession = restoreSavedSession
        ? await _gameStateService.loadSession(
            levelName: level.name,
            gameNumber: game.gameNumber,
          )
        : null;
    final activeSession = restoredSession != null &&
            _shouldDiscardRestoredSession(
              session: restoredSession,
              game: game,
            )
        ? null
        : restoredSession;

    if (restoredSession != null && activeSession == null) {
      await clear(level: level, gameNumber: game.gameNumber);
    }
    if (!restoreSavedSession) {
      await clear(level: level, gameNumber: game.gameNumber);
    }

    var restoredBoard = activeSession?.board;
    if (restoredBoard != null &&
        !_gameStateService.isBoardCompatible(
          originalBoard: game.board,
          restoredBoard: restoredBoard,
        )) {
      await clear(level: level, gameNumber: game.gameNumber);
      restoredBoard = null;
    }

    return GameSessionBootstrap(
      initialBoard: restoredBoard ?? game.board,
      activeSession: restoredBoard == null ? null : activeSession,
    );
  }

  void scheduleSave({
    required SudokuLevel level,
    required int gameNumber,
    required GameSessionSnapshot snapshot,
  }) {
    _saveTimer?.cancel();
    _saveTimer = Timer(debounceDuration, () {
      unawaited(
        flushSave(
          level: level,
          gameNumber: gameNumber,
          snapshot: snapshot,
        ),
      );
    });
  }

  Future<void> flushSave({
    required SudokuLevel level,
    required int gameNumber,
    required GameSessionSnapshot snapshot,
  }) async {
    _saveTimer?.cancel();
    _saveTimer = null;

    if (snapshot.isGameComplete || snapshot.isGameOver) {
      await clear(level: level, gameNumber: gameNumber);
      return;
    }

    await _gameStateService.saveSession(
      levelName: level.name,
      gameNumber: gameNumber,
      board: snapshot.board,
      notes: snapshot.notes,
      elapsedSeconds: snapshot.elapsedSeconds,
      hintsRemaining: snapshot.hintsRemaining,
      wrongCount: snapshot.wrongCount,
      isMemoMode: snapshot.isMemoMode,
      hintCells: snapshot.hintCells,
      isGameComplete: snapshot.isGameComplete,
      isGameOver: snapshot.isGameOver,
    );
  }

  Future<void> clear({
    required SudokuLevel level,
    required int gameNumber,
  }) async {
    await _gameStateService.clearBoard(
      levelName: level.name,
      gameNumber: gameNumber,
    );
  }

  void dispose() {
    _saveTimer?.cancel();
    _saveTimer = null;
  }

  bool _shouldDiscardRestoredSession({
    required GameSessionState session,
    required SudokuGame game,
  }) {
    if (session.isGameComplete || session.isGameOver || session.wrongCount >= 3) {
      return true;
    }

    return _gameStateService.isBoardCompatible(
      originalBoard: game.solution,
      restoredBoard: session.board,
    );
  }
}
