import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/utils/board_codec.dart';

class SavedGameState {
  const SavedGameState({
    required this.levelName,
    required this.gameNumber,
    required this.board,
    required this.lastPlayedAtMillis,
  });

  final String levelName;
  final int gameNumber;
  final List<List<int>> board;
  final int lastPlayedAtMillis;
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
  static const String _gamePrefix = 'game_';
  static const String _metaPrefix = 'game_meta_';
  static final RegExp _savedGameKeyPattern = RegExp(r'^game_(.+)_(\d+)$');

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
    final prefs = await SharedPreferences.getInstance();
    final key = _gameKey(levelName, gameNumber);
    final metaKey = _metaKey(levelName, gameNumber);
    final payload = jsonEncode({
      'board': board,
      'notes': notes
          .map(
            (row) => row
                .map((cellNotes) => cellNotes.toList()..sort())
                .toList(),
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
    await prefs.setInt(metaKey, DateTime.now().millisecondsSinceEpoch);

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

    final session = _decodeSessionPayload(payload);

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

      final session = _decodeSessionPayload(payload);

      savedGames.add(
        SavedGameState(
          levelName: levelName,
          gameNumber: gameNumber,
          board: session.board,
          lastPlayedAtMillis: prefs.getInt(_metaKey(levelName, gameNumber)) ?? 0,
        ),
      );
    }

    savedGames.sort((a, b) => b.lastPlayedAtMillis.compareTo(a.lastPlayedAtMillis));
    return savedGames;
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
          .map((row) => (row as List<dynamic>).map((cell) => cell as int).toList())
          .toList(),
      notes: List.generate(9, (row) {
        final rowData =
            row < rawNotes.length ? rawNotes[row] as List<dynamic>? : null;
        return List.generate(9, (col) {
          final cellData =
              rowData != null && col < rowData.length
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
}
