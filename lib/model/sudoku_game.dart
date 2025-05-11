import 'dart:convert';

class SudokuGame {
  final List<List<int>> board;
  final List<List<int>> solution;
  final int emptyCells;
  final String levelName;
  final int gameNumber;

  SudokuGame({
    required this.board,
    required this.solution,
    required this.emptyCells,
    required this.levelName,
    required this.gameNumber,
  });

  factory SudokuGame.fromJson(Map<String, dynamic> json) {
    return SudokuGame(
      board: List<List<int>>.from(
        jsonDecode(json['board']).map((row) => List<int>.from(row)),
      ),
      solution: List<List<int>>.from(
        jsonDecode(json['solution']).map((row) => List<int>.from(row)),
      ),
      emptyCells: json['empty_cells'] as int,
      levelName: json['level_name'] as String,
      gameNumber: json['game_number'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'board': jsonEncode(board),
      'solution': jsonEncode(solution),
      'empty_cells': emptyCells,
      'level_name': levelName,
      'game_number': gameNumber,
    };
  }
}
