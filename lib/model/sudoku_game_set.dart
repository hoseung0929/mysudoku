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
    final games = await dbHelper.getGamesForLevel(level);

    if (games.isEmpty) {
      return [];
    }

    return Future.wait(List.generate(games.length, (index) async {
      final board = games[index];
      final gameNumber = index + 1;

      print('=== 게임 생성 로그 ===');
      print('플레이 게임 game_number: $gameNumber');

      // DB에서 저장된 해답 데이터를 가져옴
      final solution = await dbHelper.getSolution(level, gameNumber);
      print('해답 조회 game_number: $gameNumber');

      // 해답 데이터가 없거나 비어있는 경우에만 동적으로 생성
      List<List<int>> finalSolution;
      if (solution.isEmpty) {
        print('경고: DB에 해답 데이터가 없습니다. 동적으로 생성합니다. (${level} - ${gameNumber})');
        finalSolution = SudokuGenerator.getSolution(board);
      } else {
        print('DB 해답 데이터 사용: ${level} - ${gameNumber}');
        finalSolution = solution;
      }

      print('=== 게임 생성 완료 ===');
      print('플레이 게임 game_number: $gameNumber');
      print('해답 game_number: $gameNumber');
      print('========================');

      return SudokuGame(
        board: board,
        solution: finalSolution,
        emptyCells: level == '초급'
            ? 30
            : level == '중급'
                ? 40
                : 50,
        levelName: level,
        gameNumber: gameNumber,
      );
    }));
  }
}
