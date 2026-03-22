import 'package:flutter/foundation.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/utils/sudoku_generator.dart';

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
  static Future<List<SudokuGame>> create(String level) async {
    final dbHelper = DatabaseHelper();
    final entries = await dbHelper.getGameEntriesForLevel(level);
    final levelInfo = SudokuLevel.levels.firstWhere(
      (item) => item.name == level,
      orElse: () => SudokuLevel.levels.first,
    );

    if (entries.isEmpty) {
      return [];
    }

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final board = entry['board'] as List<List<int>>;
      final gameNumber = entry['game_number'] as int;
      final solution = entry['solution'] as List<List<int>>;

      if (kDebugMode) {
        AppLogger.debug('게임 생성: $level 게임 $gameNumber');
      }

      List<List<int>> finalSolution;
      if (solution.isEmpty) {
        if (kDebugMode) {
          AppLogger.debug('해답 데이터 없음, 동적 생성: $level 게임 $gameNumber');
        }
        finalSolution = SudokuGenerator.getSolution(board);
      } else {
        finalSolution = solution;
      }

      return SudokuGame(
        board: board,
        solution: finalSolution,
        emptyCells: levelInfo.emptyCells,
        levelName: level,
        gameNumber: gameNumber,
      );
    });
  }
}
