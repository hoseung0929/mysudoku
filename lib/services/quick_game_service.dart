import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';

class QuickGameService {
  QuickGameService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  Future<SudokuGame?> createQuickGame(SudokuLevel level) async {
    final gameCount = await _databaseHelper.getGameCount(level.name);
    if (gameCount == 0) {
      return null;
    }

    final targetGameNumber = (level.clearedGames % gameCount) + 1;
    final board = await _databaseHelper.getGame(level.name, targetGameNumber);
    final solution =
        await _databaseHelper.getSolution(level.name, targetGameNumber);
    if (board.isEmpty || solution.isEmpty) {
      return null;
    }

    return SudokuGame(
      board: board,
      solution: solution,
      emptyCells: level.emptyCells,
      levelName: level.name,
      gameNumber: targetGameNumber,
    );
  }
}
