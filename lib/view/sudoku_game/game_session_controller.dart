import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

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
    this.cloudSyncCooldown = const Duration(seconds: 45),
  }) : _gameStateService = gameStateService ?? GameStateService();

  final GameStateService _gameStateService;
  final Duration debounceDuration;
  final Duration cloudSyncCooldown;
  Timer? _saveTimer;
  String? _pendingSaveKey;
  String? _pendingSaveSignature;
  final Map<String, String> _lastSavedSignatureByGame = <String, String>{};
  DateTime? _lastCloudSyncAt;
  bool _cloudSyncInFlight = false;

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
    final key = _sessionKey(level.name, gameNumber);
    final signature = _snapshotSignature(snapshot);
    if (_lastSavedSignatureByGame[key] == signature) {
      return;
    }
    if (_pendingSaveKey == key &&
        _pendingSaveSignature != null &&
        _pendingSaveSignature == signature) {
      return;
    }

    _pendingSaveKey = key;
    _pendingSaveSignature = signature;
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
    final key = _sessionKey(level.name, gameNumber);
    final signature = _snapshotSignature(snapshot);
    _saveTimer?.cancel();
    _saveTimer = null;
    _pendingSaveKey = null;
    _pendingSaveSignature = null;

    if (snapshot.isGameComplete || snapshot.isGameOver) {
      await clear(level: level, gameNumber: gameNumber);
      return;
    }
    if (_lastSavedSignatureByGame[key] == signature) {
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
    _lastSavedSignatureByGame[key] = signature;
  }

  Future<void> clear({
    required SudokuLevel level,
    required int gameNumber,
  }) async {
    _lastSavedSignatureByGame.remove(_sessionKey(level.name, gameNumber));
    await _gameStateService.clearBoard(
      levelName: level.name,
      gameNumber: gameNumber,
    );
  }

  Future<void> syncToCloud() async {
    if (_cloudSyncInFlight) {
      return;
    }
    final lastSyncAt = _lastCloudSyncAt;
    if (lastSyncAt != null &&
        DateTime.now().difference(lastSyncAt) < cloudSyncCooldown) {
      return;
    }
    _cloudSyncInFlight = true;
    try {
      await _gameStateService.syncToCloud();
      _lastCloudSyncAt = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('게임 세션 클라우드 업로드 실패(무시): $e');
      }
    } finally {
      _cloudSyncInFlight = false;
    }
  }

  void dispose() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _pendingSaveKey = null;
    _pendingSaveSignature = null;
  }

  String _sessionKey(String levelName, int gameNumber) {
    return '$levelName#$gameNumber';
  }

  String _snapshotSignature(GameSessionSnapshot snapshot) {
    final buffer = StringBuffer()
      ..write(snapshot.elapsedSeconds)
      ..write('|')
      ..write(snapshot.wrongCount)
      ..write('|')
      ..write(snapshot.isMemoMode ? 1 : 0)
      ..write('|')
      ..write(snapshot.hintsRemaining)
      ..write('|')
      ..write(snapshot.isGameComplete ? 1 : 0)
      ..write('|')
      ..write(snapshot.isGameOver ? 1 : 0)
      ..write('|');

    for (final row in snapshot.board) {
      for (final value in row) {
        buffer.write(value);
      }
      buffer.write('/');
    }
    buffer.write('|');

    for (final row in snapshot.notes) {
      for (final cellNotes in row) {
        if (cellNotes.isNotEmpty) {
          final sorted = cellNotes.toList()..sort();
          for (final note in sorted) {
            buffer.write(note);
          }
        }
        buffer.write(',');
      }
      buffer.write('/');
    }
    buffer.write('|');

    final hintCells = snapshot.hintCells.toList()..sort();
    for (final cell in hintCells) {
      buffer
        ..write(cell)
        ..write(',');
    }
    return buffer.toString();
  }

  bool _shouldDiscardRestoredSession({
    required GameSessionState session,
    required SudokuGame game,
  }) {
    if (session.isGameComplete ||
        session.isGameOver ||
        session.wrongCount >= 3) {
      return true;
    }

    return _gameStateService.isBoardCompatible(
      originalBoard: game.solution,
      restoredBoard: session.board,
    );
  }
}
