import 'package:flutter/material.dart';
import '../utils/sudoku_generator.dart';
import '../database/database_helper.dart';

class SudokuLevel {
  final String name;
  final String description;
  final int difficulty; // 1-5 (쉬움-어려움)
  final int emptyCells; // 비워둘 셀의 개수
  final int gameCount; // 해당 레벨의 게임 수

  const SudokuLevel({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.emptyCells,
    required this.gameCount,
  });

  // 각 레벨별 게임셋 생성
  Future<List<List<List<int>>>> generateGameSet() async {
    final dbHelper = DatabaseHelper();
    final games = await dbHelper.getGamesForLevel(name);
    if (games.isEmpty) {
      // 데이터베이스에 게임이 없는 경우 빈 보드 반환
      return List.generate(gameCount,
          (_) => List.generate(9, (_) => List.generate(9, (_) => 0)));
    }
    return games;
  }

  // 특정 게임 가져오기
  Future<List<List<int>>> getGame(int gameNumber) async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getGame(name, gameNumber);
  }

  // 특정 게임의 해답 가져오기
  Future<List<List<int>>> getSolution(int gameNumber) async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getSolution(name, gameNumber);
  }

  static const List<SudokuLevel> levels = [
    SudokuLevel(
      name: '초급',
      description: '스도쿠를 처음 시작하는 분들을 위한 레벨',
      difficulty: 1,
      emptyCells: 30,
      gameCount: 30,
    ),
    SudokuLevel(
      name: '중급',
      description: '기본적인 스도쿠 규칙을 아는 분들을 위한 레벨',
      difficulty: 2,
      emptyCells: 40,
      gameCount: 30,
    ),
    SudokuLevel(
      name: '고급',
      description: '스도쿠에 익숙한 분들을 위한 레벨',
      difficulty: 3,
      emptyCells: 50,
      gameCount: 30,
    ),
    SudokuLevel(
      name: '전문가',
      description: '스도쿠 마스터를 위한 레벨',
      difficulty: 4,
      emptyCells: 55,
      gameCount: 30,
    ),
    SudokuLevel(
      name: '마스터',
      description: '최고의 스도쿠 도전',
      difficulty: 5,
      emptyCells: 60,
      gameCount: 30,
    ),
  ];
}
