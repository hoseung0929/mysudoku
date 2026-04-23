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
    final entry = await getGameEntry(levelName, gameNumber);
    return entry == null ? [] : entry['board'] as List<List<int>>;
  }

  /// 특정 레벨의 특정 게임/해답 데이터를 함께 반환합니다.
  Future<Map<String, dynamic>?> getGameEntry(
    String levelName,
    int gameNumber,
  ) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      columns: ['game_number', 'board', 'solution'],
      where: 'level_name = ? AND game_number = ?',
      whereArgs: [levelName, gameNumber],
    );

    if (maps.isEmpty) return null;

    final entry = maps.first;
    return {
      'game_number': entry['game_number'] as int,
      'board': _parseBoardString(entry['board'] as String),
      'solution': _parseBoardString(entry['solution'] as String),
    };
  }

  /// 특정 레벨의 특정 게임의 해답을 반환합니다.
  Future<List<List<int>>> getSolution(String levelName, int gameNumber) async {
    if (kDebugMode) {
      AppLogger.debug('해답 조회 요청: $levelName 게임 $gameNumber');
    }

    final entry = await getGameEntry(levelName, gameNumber);
    if (entry == null) {
      if (kDebugMode) {
        AppLogger.debug('해답 조회 결과 없음: $levelName 게임 $gameNumber');
      }
      return [];
    }

    final solution = entry['solution'] as List<List<int>>;

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

  /// 특정 레벨에 실제로 존재하는 게임 번호 목록을 반환합니다.
  Future<List<int>> getGameNumbersForLevel(String levelName) async {
    final db = await _dbManager.database;
    final maps = await db.query(
      'games',
      columns: ['game_number'],
      where: 'level_name = ?',
      whereArgs: [levelName],
      orderBy: 'game_number ASC',
    );

    return maps
        .map((map) => map['game_number'] as int)
        .where((gameNumber) => gameNumber > 0)
        .toList();
  }

  /// 특정 레벨에서 아직 클리어하지 않은 게임 중 가장 작은 game_number를 반환합니다.
  /// games/clear_records의 (level_name, game_number) 유니크 인덱스를 활용하여
  /// 레벨별 게임 수가 많아져도 O(log n)에 가깝게 동작합니다.
  Future<int?> findFirstUnclearedGameNumber(String levelName) async {
    final db = await _dbManager.database;
    final result = await db.rawQuery(
      '''
      SELECT g.game_number
      FROM games AS g
      WHERE g.level_name = ?
        AND g.game_number > 0
        AND NOT EXISTS (
          SELECT 1
          FROM clear_records AS c
          WHERE c.level_name = g.level_name
            AND c.game_number = g.game_number
        )
      ORDER BY g.game_number ASC
      LIMIT 1
      ''',
      [levelName],
    );

    if (result.isEmpty) return null;
    return result.first['game_number'] as int;
  }
}
