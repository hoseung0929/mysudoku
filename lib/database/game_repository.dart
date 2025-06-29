import 'package:sqflite/sqflite.dart';
import 'database_manager.dart';

/// 게임 데이터 관리를 담당하는 클래스
class GameRepository {
  final DatabaseManager _dbManager = DatabaseManager();

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
      final String boardStr = map['board'] as String;
      return boardStr.split(';').map((row) {
        return row.split(',').map((cell) => int.parse(cell)).toList();
      }).toList();
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

    final String boardStr = maps.first['board'] as String;
    return boardStr.split(';').map((row) {
      return row.split(',').map((cell) => int.parse(cell)).toList();
    }).toList();
  }

  /// 특정 레벨의 특정 게임의 해답을 반환합니다.
  Future<List<List<int>>> getSolution(String levelName, int gameNumber) async {
    print('=== 해답 조회 로그 ===');
    print('해답 조회 요청 - 레벨: $levelName, game_number: $gameNumber');

    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'level_name = ? AND game_number = ?',
      whereArgs: [levelName, gameNumber],
    );

    if (maps.isEmpty) {
      print('해답 조회 결과: 데이터 없음 (레벨: $levelName, game_number: $gameNumber)');
      return [];
    }

    final String solutionStr = maps.first['solution'] as String;
    final solution = solutionStr.split(';').map((row) {
      return row.split(',').map((cell) => int.parse(cell)).toList();
    }).toList();

    print('해답 조회 성공: 레벨: $levelName, game_number: $gameNumber');
    print('========================');

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
