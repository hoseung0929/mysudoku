import '../database/database_helper.dart';

class SudokuLevel {
  final String name;
  final String description;
  final int difficulty; // 1-5 (쉬움-어려움)
  final int emptyCells; // 비워둘 셀의 개수
  final int gameCount; // 해당 레벨의 게임 수
  int clearedGames; // 클리어한 게임 수

  SudokuLevel({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.emptyCells,
    required this.gameCount,
    this.clearedGames = 0,
  });

  /// 클리어한 게임 수를 DB에서 로드합니다.
  Future<void> loadClearedGames() async {
    try {
      final dbHelper = DatabaseHelper();
      clearedGames = await dbHelper.getClearedGameCount(name);
    } catch (e) {
      print('클리어된 게임 수 로드 실패: $e');
      clearedGames = 0;
    }
  }

  /// 게임을 클리어했을 때 호출되는 메서드입니다.
  Future<void> onGameCleared() async {
    // DB에서 클리어된 게임 수를 다시 로드
    await loadClearedGames();
  }

  /// 클리어한 게임 수를 초기화합니다.
  Future<void> resetClearedGames() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.clearRecordsForLevel(name);
      clearedGames = 0;
    } catch (e) {
      print('클리어된 게임 수 초기화 실패: $e');
    }
  }

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

  // 특정 레벨의 클리어 기록 가져오기
  Future<List<Map<String, dynamic>>> getClearRecords() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getClearRecordsForLevel(name);
  }

  // 특정 레벨의 최고 기록 가져오기
  Future<Map<String, dynamic>?> getBestRecord() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getBestRecord(name);
  }

  // 특정 레벨의 평균 클리어 시간 가져오기
  Future<double> getAverageClearTime() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getAverageClearTime(name);
  }

  // 특정 레벨의 평균 오답 수 가져오기
  Future<double> getAverageWrongCount() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getAverageWrongCount(name);
  }

  static List<SudokuLevel> levels = [
    SudokuLevel(
      name: '초급',
      description: '스도쿠를 처음 시작하는 분들을 위한 레벨',
      difficulty: 1,
      emptyCells: 30,
      gameCount: 10000,
    ),
    SudokuLevel(
      name: '중급',
      description: '기본적인 스도쿠 규칙을 아는 분들을 위한 레벨',
      difficulty: 2,
      emptyCells: 40,
      gameCount: 10000,
    ),
    SudokuLevel(
      name: '고급',
      description: '스도쿠에 익숙한 분들을 위한 레벨',
      difficulty: 3,
      emptyCells: 50,
      gameCount: 10000,
    ),
    SudokuLevel(
      name: '전문가',
      description: '스도쿠 마스터를 위한 레벨',
      difficulty: 4,
      emptyCells: 55,
      gameCount: 10000,
    ),
    SudokuLevel(
      name: '마스터',
      description: '최고의 스도쿠 도전',
      difficulty: 5,
      emptyCells: 60,
      gameCount: 10000,
    ),
  ];

  /// 모든 레벨의 클리어한 게임 수를 로드합니다.
  static Future<void> loadAllClearedGames() async {
    for (var level in levels) {
      await level.loadClearedGames();
    }
  }
}
