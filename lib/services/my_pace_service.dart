import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/home_dashboard_service.dart';

/// "나만의 속도" 플로우에서 다음으로 열어야 할 게임/레벨 정보를 담는 값 객체.
class MyPaceTarget {
  const MyPaceTarget({
    required this.level,
    required this.game,
    required this.restoreSavedSession,
  });

  final SudokuLevel level;
  final SudokuGame game;
  final bool restoreSavedSession;
}

/// "나만의 속도" 버튼을 눌렀을 때 어떤 게임을 열어야 할지를 결정하는 서비스.
///
/// 우선순위:
/// 1. 저장된 이어하기 세션(`ContinueGameSummary`)이 있으면 그 게임을 복원.
/// 2. 그렇지 않으면 `초급 → 마스터` 순서(직전 클리어 레벨 다음부터 순회)로
///    아직 클리어하지 않은 가장 작은 `game_number`를 탐색.
/// 3. 끝까지 없으면 `null`을 반환하여 호출부에서 "플레이할 게임이 없어요" 안내를
///    보여줄 수 있도록 한다.
class MyPaceService {
  MyPaceService({
    DatabaseHelper? databaseHelper,
    Future<List<Map<String, dynamic>>> Function({int limit})?
        loadRecentClearEvents,
    Future<int?> Function(String levelName)? findFirstUnclearedGameNumber,
    Future<Map<String, dynamic>?> Function(String levelName, int gameNumber)?
        loadGameEntry,
  })  : _loadRecentClearEvents =
            loadRecentClearEvents ??
                (databaseHelper ?? DatabaseHelper()).getRecentClearEvents,
        _findFirstUnclearedGameNumber =
            findFirstUnclearedGameNumber ??
                (databaseHelper ?? DatabaseHelper()).findFirstUnclearedGameNumber,
        _loadGameEntry =
            loadGameEntry ??
                (databaseHelper ?? DatabaseHelper()).getGameEntry;

  final Future<List<Map<String, dynamic>>> Function({int limit})
      _loadRecentClearEvents;
  final Future<int?> Function(String levelName) _findFirstUnclearedGameNumber;
  final Future<Map<String, dynamic>?> Function(String levelName, int gameNumber)
      _loadGameEntry;

  /// 이어하기 세션과 신규 퍼즐 탐색을 모두 포함한 최종 타깃을 반환한다.
  ///
  /// 이미 `ContinueGameSummary`를 로드해둔 화면에서는 [preferContinueGame]
  /// 에 넘겨 중복 로드를 피할 수 있다. 값이 `null`인 경우 이어하기가 없다고
  /// 간주하고 곧바로 다음 퍼즐 탐색으로 진입한다.
  Future<MyPaceTarget?> resolveTarget({
    ContinueGameSummary? preferContinueGame,
  }) async {
    if (preferContinueGame != null) {
      return MyPaceTarget(
        level: preferContinueGame.level,
        game: preferContinueGame.game,
        restoreSavedSession: true,
      );
    }
    return resolveNextPlayableTarget();
  }

  /// 이어하기는 고려하지 않고, 레벨 순회를 통해 새 퍼즐만 탐색한다.
  Future<MyPaceTarget?> resolveNextPlayableTarget() async {
    const orderedLevels = SudokuLevel.levels;
    if (orderedLevels.isEmpty) {
      return null;
    }

    final recentClearEvents =
        await _loadRecentClearEvents(limit: 1);
    final lastClearedLevelName = recentClearEvents.isEmpty
        ? null
        : recentClearEvents.first['level_name'] as String?;

    final startIndex = _indexAfterLastClearedLevel(lastClearedLevelName);
    for (var offset = 0; offset < orderedLevels.length; offset++) {
      final level =
          orderedLevels[(startIndex + offset) % orderedLevels.length];
      final gameNumber =
          await _findFirstUnclearedGameNumber(level.name);
      if (gameNumber == null) continue;

      final entry = await _loadGameEntry(level.name, gameNumber);
      if (entry == null) continue;

      final game = SudokuGame(
        board: entry['board'] as List<List<int>>,
        solution: entry['solution'] as List<List<int>>,
        emptyCells: level.emptyCells,
        levelName: level.name,
        gameNumber: entry['game_number'] as int,
      );
      return MyPaceTarget(
        level: level,
        game: game,
        restoreSavedSession: false,
      );
    }

    return null;
  }

  int _indexAfterLastClearedLevel(String? levelName) {
    if (levelName == null) {
      return 0;
    }
    const orderedLevels = SudokuLevel.levels;
    final currentIndex =
        orderedLevels.indexWhere((item) => item.name == levelName);
    if (currentIndex < 0) {
      return 0;
    }
    return (currentIndex + 1) % orderedLevels.length;
  }
}
