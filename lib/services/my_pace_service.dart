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
/// 2. 최근 클리어 이벤트에 레벨·게임 번호가 있으면, **그 레벨에서** 방금 깬 번호보다
///    큰 미클리어 최소값 → 없으면 그 레벨의 미클리어 최소값 순으로 시도.
/// 3. 그렇지 않으면 `초급 → 마스터` 순서(직전 클리어 레벨 다음부터 순회)로
///    아직 클리어하지 않은 가장 작은 `game_number`를 탐색.
/// 4. 끝까지 없으면 `null`을 반환하여 호출부에서 "플레이할 게임이 없어요" 안내를
///    보여줄 수 있도록 한다.
class MyPaceService {
  MyPaceService({
    DatabaseHelper? databaseHelper,
    Future<List<Map<String, dynamic>>> Function({int limit})?
        loadRecentClearEvents,
    Future<int?> Function(String levelName)? findFirstUnclearedGameNumber,
    Future<int?> Function(String levelName, int afterGameNumber)?
        findFirstUnclearedGameNumberAfter,
    Future<bool> Function(String levelName, int gameNumber)? isGameCleared,
    Future<Map<String, dynamic>?> Function(String levelName, int gameNumber)?
        loadGameEntry,
  })  : _loadRecentClearEvents =
            loadRecentClearEvents ??
                (databaseHelper ?? DatabaseHelper()).getRecentClearEvents,
        _findFirstUnclearedGameNumber =
            findFirstUnclearedGameNumber ??
                (databaseHelper ?? DatabaseHelper()).findFirstUnclearedGameNumber,
        _findFirstUnclearedGameNumberAfter =
            findFirstUnclearedGameNumberAfter ??
                (databaseHelper ?? DatabaseHelper())
                    .findFirstUnclearedGameNumberAfter,
        _isGameCleared =
            isGameCleared ??
                ((levelName, gameNumber) async =>
                    (await (databaseHelper ?? DatabaseHelper())
                            .getClearRecord(levelName, gameNumber)) !=
                        null),
        _loadGameEntry =
            loadGameEntry ??
                (databaseHelper ?? DatabaseHelper()).getGameEntry;

  final Future<List<Map<String, dynamic>>> Function({int limit})
      _loadRecentClearEvents;
  final Future<int?> Function(String levelName) _findFirstUnclearedGameNumber;
  final Future<int?> Function(String levelName, int afterGameNumber)
      _findFirstUnclearedGameNumberAfter;
  final Future<bool> Function(String levelName, int gameNumber) _isGameCleared;
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
      final continueCleared = await _isGameCleared(
        preferContinueGame.level.name,
        preferContinueGame.game.gameNumber,
      );
      if (!continueCleared) {
        return MyPaceTarget(
          level: preferContinueGame.level,
          game: preferContinueGame.game,
          restoreSavedSession: true,
        );
      }
      return _resolveFromAnchor(
        levelName: preferContinueGame.level.name,
        gameNumber: preferContinueGame.game.gameNumber,
      );
    }
    return resolveNextPlayableTarget();
  }

  /// 이어하기는 고려하지 않고, 레벨 순회를 통해 새 퍼즐만 탐색한다.
  Future<MyPaceTarget?> resolveNextPlayableTarget() async {
    final recentClearEvents =
        await _loadRecentClearEvents(limit: 1);
    final lastEvent = recentClearEvents.isEmpty ? null : recentClearEvents.first;
    final lastClearedLevelName =
        lastEvent == null ? null : lastEvent['level_name'] as String?;
    final lastClearedGameNumber = _readGameNumber(lastEvent);

    if (lastClearedLevelName != null && lastClearedGameNumber != null) {
      return _resolveFromAnchor(
        levelName: lastClearedLevelName,
        gameNumber: lastClearedGameNumber,
      );
    }

    const orderedLevels = SudokuLevel.levels;
    if (orderedLevels.isEmpty) {
      return null;
    }

    final startIndex = _indexAfterLastClearedLevel(lastClearedLevelName);
    for (var offset = 0; offset < orderedLevels.length; offset++) {
      final level =
          orderedLevels[(startIndex + offset) % orderedLevels.length];
      final gameNumber = await _findFirstUnclearedGameNumber(level.name);
      if (gameNumber == null) continue;

      final target = await _targetFor(level: level, gameNumber: gameNumber);
      if (target != null) return target;
    }

    return null;
  }

  Future<MyPaceTarget?> _resolveFromAnchor({
    required String levelName,
    required int gameNumber,
  }) async {
    const orderedLevels = SudokuLevel.levels;
    if (orderedLevels.isEmpty) return null;

    final sameLevel = orderedLevels.firstWhere(
      (item) => item.name == levelName,
      orElse: () => orderedLevels.first,
    );

    final nextInSameLevel = await _findFirstUnclearedGameNumberAfter(
      sameLevel.name,
      gameNumber,
    );
    if (nextInSameLevel != null) {
      final target = await _targetFor(
        level: sameLevel,
        gameNumber: nextInSameLevel,
      );
      if (target != null) return target;
    }

    final startIndex = _indexAfterLastClearedLevel(sameLevel.name);
    for (var offset = 0; offset < orderedLevels.length; offset++) {
      final level = orderedLevels[(startIndex + offset) % orderedLevels.length];
      if (level.name == sameLevel.name) {
        continue;
      }
      final firstUncleared = await _findFirstUnclearedGameNumber(level.name);
      if (firstUncleared == null) continue;
      final target = await _targetFor(level: level, gameNumber: firstUncleared);
      if (target != null) return target;
    }

    return null;
  }

  Future<MyPaceTarget?> _targetFor({
    required SudokuLevel level,
    required int gameNumber,
  }) async {
    final entry = await _loadGameEntry(level.name, gameNumber);
    if (entry == null) return null;
    return MyPaceTarget(
      level: level,
      game: SudokuGame(
        board: entry['board'] as List<List<int>>,
        solution: entry['solution'] as List<List<int>>,
        emptyCells: level.emptyCells,
        levelName: level.name,
        gameNumber: entry['game_number'] as int,
      ),
      restoreSavedSession: false,
    );
  }

  int? _readGameNumber(Map<String, dynamic>? event) {
    if (event == null) return null;
    final raw = event['game_number'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
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
