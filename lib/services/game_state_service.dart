import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mysudoku/services/cloud_game_sync_service.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/utils/board_codec.dart';

class SavedGameState {
  const SavedGameState({
    required this.levelName,
    required this.gameNumber,
    required this.board,
    required this.lastPlayedAtMillis,
    required this.session,
  });

  final String levelName;
  final int gameNumber;
  final List<List<int>> board;
  final int lastPlayedAtMillis;
  final GameSessionState session;
}

class GameSessionState {
  const GameSessionState({
    required this.board,
    required this.notes,
    required this.elapsedSeconds,
    required this.hintsRemaining,
    required this.wrongCount,
    required this.isMemoMode,
    required this.hintCells,
    required this.isGameComplete,
    required this.isGameOver,
  });

  final List<List<int>> board;
  final List<List<Set<int>>> notes;
  final int elapsedSeconds;
  final int hintsRemaining;
  final int wrongCount;
  final bool isMemoMode;
  final Set<String> hintCells;
  final bool isGameComplete;
  final bool isGameOver;
}

class GameStateService {
  GameStateService({
    CloudGameSyncService? cloudSyncService,
  }) : _cloudSyncService = cloudSyncService ?? FirestoreCloudGameSyncService();

  static const String _gamePrefix = 'game_';
  static const String _metaPrefix = 'game_meta_';
  static const int _boardSize = 9;
  static final RegExp _savedGameKeyPattern = RegExp(r'^game_(.+)_(\d+)$');

  final CloudGameSyncService _cloudSyncService;

  String _gameKey(String levelName, int gameNumber) {
    return 'game_${levelName}_$gameNumber';
  }

  String _metaKey(String levelName, int gameNumber) {
    return 'game_meta_${levelName}_$gameNumber';
  }

  Future<void> saveSession({
    required String levelName,
    required int gameNumber,
    required List<List<int>> board,
    required List<List<Set<int>>> notes,
    required int elapsedSeconds,
    required int hintsRemaining,
    required int wrongCount,
    required bool isMemoMode,
    Set<String> hintCells = const <String>{},
    bool isGameComplete = false,
    bool isGameOver = false,
  }) async {
    final updatedAtMillis = DateTime.now().millisecondsSinceEpoch;
    await _persistLocalSession(
      levelName: levelName,
      gameNumber: gameNumber,
      board: board,
      notes: notes,
      elapsedSeconds: elapsedSeconds,
      hintsRemaining: hintsRemaining,
      wrongCount: wrongCount,
      isMemoMode: isMemoMode,
      hintCells: hintCells,
      isGameComplete: isGameComplete,
      isGameOver: isGameOver,
      updatedAtMillis: updatedAtMillis,
    );
  }

  Future<void> _persistLocalSession({
    required String levelName,
    required int gameNumber,
    required List<List<int>> board,
    required List<List<Set<int>>> notes,
    required int elapsedSeconds,
    required int hintsRemaining,
    required int wrongCount,
    required bool isMemoMode,
    required Set<String> hintCells,
    required bool isGameComplete,
    required bool isGameOver,
    required int updatedAtMillis,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _gameKey(levelName, gameNumber);
    final metaKey = _metaKey(levelName, gameNumber);
    final payload = jsonEncode({
      'board': board,
      'notes': notes
          .map(
            (row) =>
                row.map((cellNotes) => cellNotes.toList()..sort()).toList(),
          )
          .toList(),
      'elapsedSeconds': elapsedSeconds,
      'hintsRemaining': hintsRemaining,
      'wrongCount': wrongCount,
      'isMemoMode': isMemoMode,
      'hintCells': hintCells.toList()..sort(),
      'isGameComplete': isGameComplete,
      'isGameOver': isGameOver,
    });

    await prefs.setString(key, payload);
    await prefs.setInt(metaKey, updatedAtMillis);

    if (kDebugMode) {
      AppLogger.debug('게임 세션 저장 완료: $key');
    }
  }

  Future<void> saveBoard({
    required String levelName,
    required int gameNumber,
    required List<List<int>> board,
  }) async {
    await saveSession(
      levelName: levelName,
      gameNumber: gameNumber,
      board: board,
      notes: List.generate(
        9,
        (_) => List.generate(9, (_) => <int>{}),
      ),
      elapsedSeconds: 0,
      hintsRemaining: 3,
      wrongCount: 0,
      isMemoMode: false,
    );
  }

  Future<GameSessionState?> loadSession({
    required String levelName,
    required int gameNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _gameKey(levelName, gameNumber);

    if (kDebugMode) {
      AppLogger.debug('게임 세션 로딩 시도: $key');
    }

    final payload = prefs.getString(key);
    if (payload == null) {
      if (kDebugMode) {
        AppLogger.debug('저장된 게임 세션 없음: $key');
      }
      return null;
    }

    final session = _tryDecodeSessionPayload(payload);
    if (session == null) {
      await clearBoard(levelName: levelName, gameNumber: gameNumber);
      if (kDebugMode) {
        AppLogger.debug('손상된 게임 세션 삭제: $key');
      }
      return null;
    }

    if (kDebugMode) {
      AppLogger.debug('게임 세션 복원 완료: $key');
    }

    return session;
  }

  Future<List<List<int>>?> loadBoard({
    required String levelName,
    required int gameNumber,
  }) async {
    final session = await loadSession(
      levelName: levelName,
      gameNumber: gameNumber,
    );
    return session?.board;
  }

  Future<void> clearBoard({
    required String levelName,
    required int gameNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _gameKey(levelName, gameNumber);
    final metaKey = _metaKey(levelName, gameNumber);

    await prefs.remove(key);
    await prefs.remove(metaKey);

    _runCloudTask(
      () => _cloudSyncService.deleteSave(
        levelName: levelName,
        gameNumber: gameNumber,
      ),
      action: '저장 삭제',
    );

    if (kDebugMode) {
      AppLogger.debug('게임 상태 삭제 완료: $key');
    }
  }

  bool isBoardCompatible({
    required List<List<int>> originalBoard,
    required List<List<int>> restoredBoard,
  }) {
    if (restoredBoard.length != originalBoard.length) {
      return false;
    }

    for (int row = 0; row < restoredBoard.length; row++) {
      if (restoredBoard[row].length != originalBoard[row].length) {
        return false;
      }
      for (int col = 0; col < restoredBoard[row].length; col++) {
        if (originalBoard[row][col] != 0 &&
            restoredBoard[row][col] != originalBoard[row][col]) {
          return false;
        }
      }
    }

    return true;
  }

  Future<List<SavedGameState>> getSavedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGames = <SavedGameState>[];

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_gamePrefix) || key.startsWith(_metaPrefix)) {
        continue;
      }

      final match = _savedGameKeyPattern.firstMatch(key);
      if (match == null) {
        continue;
      }

      final payload = prefs.get(key);
      if (payload is! String) {
        continue;
      }

      final levelName = match.group(1)!;
      final gameNumber = int.parse(match.group(2)!);

      final session = _tryDecodeSessionPayload(payload);
      if (session == null) {
        await prefs.remove(key);
        await prefs.remove(_metaKey(levelName, gameNumber));
        continue;
      }

      savedGames.add(
        SavedGameState(
          levelName: levelName,
          gameNumber: gameNumber,
          board: session.board,
          lastPlayedAtMillis:
              prefs.getInt(_metaKey(levelName, gameNumber)) ?? 0,
          session: session,
        ),
      );
    }

    savedGames
        .sort((a, b) => b.lastPlayedAtMillis.compareTo(a.lastPlayedAtMillis));
    return savedGames;
  }

  Future<void> syncFromCloud() async {
    final prefs = await SharedPreferences.getInstance();
    final cloudSaves = await _cloudSyncService.fetchSaves();

    for (final save in cloudSaves) {
      final localUpdatedAt =
          prefs.getInt(_metaKey(save.levelName, save.gameNumber)) ?? 0;
      if (localUpdatedAt >= save.updatedAtMillis) {
        continue;
      }

      await _persistLocalSession(
        levelName: save.levelName,
        gameNumber: save.gameNumber,
        board: save.board,
        notes: save.notes,
        elapsedSeconds: save.elapsedSeconds,
        hintsRemaining: save.hintsRemaining,
        wrongCount: save.wrongCount,
        isMemoMode: save.isMemoMode,
        hintCells: save.hintCells,
        isGameComplete: save.isGameComplete,
        isGameOver: save.isGameOver,
        updatedAtMillis: save.updatedAtMillis,
      );
    }
  }

  Future<void> syncToCloud() async {
    final localSaves = await getSavedGames();

    for (final save in localSaves) {
      await _cloudSyncService.upsertSave(
        CloudGameSavePayload(
          levelName: save.levelName,
          gameNumber: save.gameNumber,
          board: save.session.board,
          notes: save.session.notes,
          elapsedSeconds: save.session.elapsedSeconds,
          hintsRemaining: save.session.hintsRemaining,
          wrongCount: save.session.wrongCount,
          isMemoMode: save.session.isMemoMode,
          hintCells: save.session.hintCells,
          isGameComplete: save.session.isGameComplete,
          isGameOver: save.session.isGameOver,
          updatedAtMillis: save.lastPlayedAtMillis,
        ),
      );
    }
  }

  Future<void> syncBidirectional() async {
    await syncFromCloud();
    await syncToCloud();
  }

  GameSessionState _decodeSessionPayload(String payload) {
    if (!payload.trimLeft().startsWith('{')) {
      return GameSessionState(
        board: BoardCodec.decode(payload),
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
        elapsedSeconds: 0,
        hintsRemaining: 3,
        wrongCount: 0,
        isMemoMode: false,
        hintCells: <String>{},
        isGameComplete: false,
        isGameOver: false,
      );
    }

    final json = jsonDecode(payload) as Map<String, dynamic>;
    final rawBoard = json['board'] as List<dynamic>? ?? const [];
    final rawNotes = json['notes'] as List<dynamic>? ?? const [];
    final rawHintCells = json['hintCells'] as List<dynamic>? ?? const [];

    return GameSessionState(
      board: rawBoard
          .map((row) =>
              (row as List<dynamic>).map((cell) => cell as int).toList())
          .toList(),
      notes: List.generate(9, (row) {
        final rowData =
            row < rawNotes.length ? rawNotes[row] as List<dynamic>? : null;
        return List.generate(9, (col) {
          final cellData = rowData != null && col < rowData.length
              ? rowData[col] as List<dynamic>? ?? const []
              : const <dynamic>[];
          return cellData.map((value) => value as int).toSet();
        });
      }),
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      hintsRemaining: json['hintsRemaining'] as int? ?? 3,
      wrongCount: json['wrongCount'] as int? ?? 0,
      isMemoMode: json['isMemoMode'] as bool? ?? false,
      hintCells: rawHintCells.map((cell) => cell as String).toSet(),
      isGameComplete: json['isGameComplete'] as bool? ?? false,
      isGameOver: json['isGameOver'] as bool? ?? false,
    );
  }

  GameSessionState? _tryDecodeSessionPayload(String payload) {
    try {
      final session = _decodeSessionPayload(payload);
      return _isValidSessionState(session) ? session : null;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('게임 세션 디코드 실패: $e');
      }
      return null;
    }
  }

  bool _isValidSessionState(GameSessionState session) {
    return _isValidBoard(session.board) &&
        _isValidNotes(session.notes) &&
        session.elapsedSeconds >= 0 &&
        session.hintsRemaining >= 0 &&
        session.wrongCount >= 0;
  }

  bool _isValidBoard(List<List<int>> board) {
    if (board.length != _boardSize) {
      return false;
    }

    for (final row in board) {
      if (row.length != _boardSize) {
        return false;
      }
      for (final cell in row) {
        if (cell < 0 || cell > 9) {
          return false;
        }
      }
    }

    return true;
  }

  bool _isValidNotes(List<List<Set<int>>> notes) {
    if (notes.length != _boardSize) {
      return false;
    }

    for (final row in notes) {
      if (row.length != _boardSize) {
        return false;
      }
      for (final cellNotes in row) {
        for (final value in cellNotes) {
          if (value < 1 || value > 9) {
            return false;
          }
        }
      }
    }

    return true;
  }

  void _runCloudTask(
    Future<void> Function() task, {
    required String action,
  }) {
    unawaited(() async {
      try {
        await task();
      } catch (e) {
        if (kDebugMode) {
          AppLogger.debug('클라우드 동기화($action) 실패: $e');
        }
      }
    }());
  }
}
