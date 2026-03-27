import 'package:flutter/foundation.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';
import 'database_manager.dart';
import 'package:mysudoku/utils/board_codec.dart';

/// 게임 데이터 관리를 담당하는 클래스
class GameRepository {
  final DatabaseManager _dbManager = DatabaseManager();

  List<List<int>> _parseBoardString(String boardStr) {
    return BoardCodec.decode(boardStr);
  }

  /// 특정 레벨의 모든 게임 데이터를 반환합니다.
  Future<List<List<List<int>>>> getGamesForLevel(String levelName) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'level_name = ?',
      whereArgs: [levelName],
      orderBy: 'game_number ASC',
    );

    return maps.map((map) {
      return _parseBoardString(map['board'] as String);
    }).toList();
  }

  /// 특정 레벨의 게임/해답 데이터를 함께 반환합니다.
  Future<List<Map<String, dynamic>>> getGameEntriesForLevel(
      String levelName) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      columns: ['game_number', 'board', 'solution'],
      where: 'level_name = ?',
      whereArgs: [levelName],
      orderBy: 'game_number ASC',
    );

    return maps.map((map) {
      return {
        'game_number': map['game_number'] as int,
        'board': _parseBoardString(map['board'] as String),
        'solution': _parseBoardString(map['solution'] as String),
      };
    }).toList();
  }

  /// 특정 레벨의 특정 게임 데이터를 반환합니다.
  Future<List<List<int>>> getGame(String levelName, int gameNumber) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'level_name = ? AND game_number = ?',
      whereArgs: [levelName, gameNumber],
    );

    if (maps.isEmpty) return [];

    return _parseBoardString(maps.first['board'] as String);
  }

  /// 특정 레벨의 특정 게임의 해답을 반환합니다.
  Future<List<List<int>>> getSolution(String levelName, int gameNumber) async {
    if (kDebugMode) {
      AppLogger.debug('해답 조회 요청: $levelName 게임 $gameNumber');
    }

    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'level_name = ? AND game_number = ?',
      whereArgs: [levelName, gameNumber],
    );

    if (maps.isEmpty) {
      if (kDebugMode) {
        AppLogger.debug('해답 조회 결과 없음: $levelName 게임 $gameNumber');
      }
      return [];
    }

    final solution = _parseBoardString(maps.first['solution'] as String);

    if (kDebugMode) {
      AppLogger.debug('해답 조회 성공: $levelName 게임 $gameNumber');
    }

    return solution;
  }

  /// 특정 레벨의 게임 수를 반환합니다.
  Future<int> getGameCount(String levelName) async {
    final db = await _dbManager.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM games WHERE level_name = ?',
      [levelName],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
