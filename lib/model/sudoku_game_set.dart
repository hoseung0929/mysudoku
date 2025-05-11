import 'sudoku_level.dart';
import 'sudoku_game.dart';
import '../database/database_helper.dart';

class SudokuGameSet {
  final SudokuLevel level;
  List<List<List<int>>> games;
  int currentGameIndex;

  SudokuGameSet({
    required this.level,
    required this.games,
    this.currentGameIndex = 0,
  });

  // 현재 게임 가져오기
  List<List<int>> get currentGame => games[currentGameIndex];

  // 다음 게임으로 이동
  bool moveToNextGame() {
    if (currentGameIndex < games.length - 1) {
      currentGameIndex++;
      return true;
    }
    return false;
  }

  // 이전 게임으로 이동
  bool moveToPreviousGame() {
    if (currentGameIndex > 0) {
      currentGameIndex--;
      return true;
    }
    return false;
  }

  // 게임 진행률 계산
  double get progress => (currentGameIndex + 1) / games.length;

  // 남은 게임 수
  int get remainingGames => games.length - (currentGameIndex + 1);

  // 게임셋 생성
  static Future<List<SudokuGame>> create(SudokuLevel level) async {
    final db = await DatabaseHelper.instance.database;
    final games = await db.query(
      'games',
      where: 'level_name = ?',
      whereArgs: [level.name],
      orderBy: 'game_number ASC',
    );

    if (games.isEmpty) {
      return [];
    }

    return games.map((game) => SudokuGame.fromJson(game)).toList();
  }
}
