import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mysudoku/utils/app_logger.dart';

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

class GameStateService {
  static const String _gamePrefix = 'game_';
  static const String _metaPrefix = 'game_meta_';

  String _gameKey(String levelName, int gameNumber) {
    return 'game_${levelName}_$gameNumber';
  }

  String _metaKey(String levelName, int gameNumber) {
    return 'game_meta_${levelName}_$gameNumber';
  }

  Future<void> saveBoard({
    required String levelName,
    required int gameNumber,
    required List<List<int>> board,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final boardString = board.map((row) => row.join(',')).join(';');
    final key = _gameKey(levelName, gameNumber);
    final metaKey = _metaKey(levelName, gameNumber);

    await prefs.setString(key, boardString);
    await prefs.setInt(metaKey, DateTime.now().millisecondsSinceEpoch);

    if (kDebugMode) {
      AppLogger.debug('게임 상태 저장 완료: $key');
    }
  }

  Future<List<List<int>>?> loadBoard({
    required String levelName,
    required int gameNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _gameKey(levelName, gameNumber);

    if (kDebugMode) {
      AppLogger.debug('게임 상태 로딩 시도: $key');
    }

    final boardString = prefs.getString(key);
    if (boardString == null) {
      if (kDebugMode) {
        AppLogger.debug('저장된 게임 상태 없음: $key');
      }
      return null;
    }

    final rows = boardString.split(';');
    final board = rows
        .map((row) => row.split(',').map((cell) => int.parse(cell)).toList())
        .toList();

    if (kDebugMode) {
      AppLogger.debug('게임 상태 복원 완료: $key');
    }

    return board;
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

      final payload = prefs.getString(key);
      if (payload == null) {
        continue;
      }

      final identifier = key.substring(_gamePrefix.length);
      final separatorIndex = identifier.lastIndexOf('_');
      if (separatorIndex <= 0 || separatorIndex == identifier.length - 1) {
        continue;
      }

      final levelName = identifier.substring(0, separatorIndex);
      final gameNumber = int.tryParse(identifier.substring(separatorIndex + 1));
      if (gameNumber == null) {
        continue;
      }

      final rows = payload.split(';');
      final board = rows
          .map((row) => row.split(',').map((cell) => int.parse(cell)).toList())
          .toList();

      savedGames.add(
        SavedGameState(
          levelName: levelName,
          gameNumber: gameNumber,
          board: board,
          lastPlayedAtMillis: prefs.getInt(_metaKey(levelName, gameNumber)) ?? 0,
        ),
      );
    }

    savedGames.sort((a, b) => b.lastPlayedAtMillis.compareTo(a.lastPlayedAtMillis));
    return savedGames;
  }
}
