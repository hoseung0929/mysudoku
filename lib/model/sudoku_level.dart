class SudokuLevel {
  final String name;
  final String description;
  final int difficulty; // 1-5 (쉬움-어려움)
  final int emptyCells; // 비워둘 셀의 개수

  const SudokuLevel({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.emptyCells,
  });

  static const List<SudokuLevel> levels = [
    SudokuLevel(
      name: '초급',
      description: '스도쿠를 처음 시작하는 분들을 위한 레벨',
      difficulty: 1,
      emptyCells: 30,
    ),
    SudokuLevel(
      name: '중급',
      description: '기본적인 스도쿠 규칙을 아는 분들을 위한 레벨',
      difficulty: 2,
      emptyCells: 40,
    ),
    SudokuLevel(
      name: '고급',
      description: '스도쿠에 익숙한 분들을 위한 레벨',
      difficulty: 3,
      emptyCells: 50,
    ),
    SudokuLevel(
      name: '전문가',
      description: '스도쿠 마스터를 위한 레벨',
      difficulty: 4,
      emptyCells: 55,
    ),
    SudokuLevel(
      name: '마스터',
      description: '최고의 스도쿠 도전',
      difficulty: 5,
      emptyCells: 60,
    ),
  ];
}
