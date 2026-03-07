import 'package:flutter/foundation.dart';
import 'sudoku_level.dart';
import 'sudoku_game.dart';
import '../database/database_helper.dart';
import '../utils/sudoku_generator.dart';

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
        print('=== 게임 생성 로그 ===');
        print('플레이 게임 game_number: $gameNumber');
      }

      List<List<int>> finalSolution;
      if (solution.isEmpty) {
        if (kDebugMode) {
          print('경고: DB에 해답 데이터가 없습니다. 동적으로 생성합니다. ($level - $gameNumber)');
        }
        finalSolution = SudokuGenerator.getSolution(board);
      } else {
        finalSolution = solution;
      }

      if (kDebugMode) {
        print('=== 게임 생성 완료 ===');
        print('플레이 게임 game_number: $gameNumber');
        print('해답 game_number: $gameNumber');
        print('========================');
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
