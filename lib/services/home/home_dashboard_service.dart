import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_game_feature_policy.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/game/game_state_service.dart';

class ContinueGameSummary {
  const ContinueGameSummary({
    required this.level,
    required this.game,
    required this.progress,
    required this.elapsedFilledCells,
    required this.lastPlayedAtMillis,
    required this.elapsedSeconds,
    required this.wrongCount,
    required this.isMemoMode,
    required this.noteCount,
  });

  final SudokuLevel level;
  final SudokuGame game;
  final double progress;
  final int elapsedFilledCells;
  final int lastPlayedAtMillis;
  final int elapsedSeconds;
  final int wrongCount;
  final bool isMemoMode;
  final int noteCount;
}

class HomeDashboardData {
  const HomeDashboardData({
    required this.continueGame,
    required this.continueGames,
    required this.totalContinueCount,
    required this.todayChallenge,
    this.todayChallengeContinueGame,
    required this.challengeProgress,
    required this.averageClearTimeSeconds,
  });

  final ContinueGameSummary? continueGame;
  final List<ContinueGameSummary> continueGames;

  /// 이어할 수 있는 게임의 전체 개수([continueGames]는 상위 몇 개만 담는다).
  final int totalContinueCount;

  /// 오늘의 도전 타깃 문제. 지정된 문제를 열 수 없으면 null (다른 문제로 대체하지 않음).
  final SudokuGame? todayChallenge;

  /// 오늘의 도전 문제의 저장 세션 요약(진행률·메모·마지막 플레이 등). 없으면 null.
  final ContinueGameSummary? todayChallengeContinueGame;

  /// 오늘의 도전 문제에 이어할 수 있는 저장 세션이 있는지.
  bool get todayChallengeHasSession => todayChallengeContinueGame != null;
  final ChallengeProgressSummary challengeProgress;
  final int averageClearTimeSeconds;
}

class HomeDashboardService {
  static const int defaultContinueGamesLimit = 3;

  HomeDashboardService({
    DatabaseHelper? databaseHelper,
    GameStateService? gameStateService,
    ChallengeProgressService? challengeProgressService,
    Future<Map<String, dynamic>?> Function(String levelName, int gameNumber)?
        loadGameEntry,
    Future<Map<String, dynamic>> Function()? loadOverallStatistics,
    Future<List<Map<String, dynamic>>> Function()? loadRecentRecords,
  })  : _gameStateService = gameStateService ?? GameStateService(),
        _challengeProgressService = challengeProgressService ??
            ChallengeProgressService(databaseHelper: databaseHelper),
        _loadGameEntry =
            loadGameEntry ?? (databaseHelper ?? DatabaseHelper()).getGameEntry,
        _loadOverallStatistics = loadOverallStatistics ??
            (databaseHelper ?? DatabaseHelper()).getOverallStatistics,
        _loadRecentRecords = loadRecentRecords ??
            (() => (databaseHelper ?? DatabaseHelper())
                .getRecentClearRecords(limit: 10000));

  final GameStateService _gameStateService;
  final ChallengeProgressService _challengeProgressService;
  final Future<Map<String, dynamic>?> Function(String levelName, int gameNumber)
      _loadGameEntry;
  final Future<Map<String, dynamic>> Function() _loadOverallStatistics;
  final Future<List<Map<String, dynamic>>> Function() _loadRecentRecords;

  Future<HomeDashboardData> load(
    AppLocalizations l10n, {
    int continueGamesLimit = defaultContinueGamesLimit,
  }) async {
    final continueGamesFuture = loadContinueGames();
    final overallStatisticsFuture = _loadOverallStatistics();
    final recentRecordsFuture = _loadRecentRecords();

    final allContinueGames = await continueGamesFuture;
    final continueGames = continueGamesLimit > 0
        ? allContinueGames.take(continueGamesLimit).toList()
        : allContinueGames;
    final continueGame = continueGames.isEmpty ? null : continueGames.first;
    final overallStatistics = await overallStatisticsFuture;
    final recentRecords = await recentRecordsFuture;
    final challengeProgress = await _challengeProgressService.load(
      recentRecords: recentRecords,
    );
    final todayChallenge = await _loadTodayChallenge(
      levelName: challengeProgress.todayChallengeLevelName,
      gameNumber: challengeProgress.todayChallengeGameNumber,
    );
    final averageClearTimeSeconds =
        (overallStatistics['total_average_time'] as num?)?.round() ?? 0;

    return HomeDashboardData(
      continueGame: continueGame,
      continueGames: continueGames,
      totalContinueCount: allContinueGames.length,
      todayChallenge: todayChallenge,
      todayChallengeContinueGame: allContinueGames
          .where((g) =>
              g.game.levelName == challengeProgress.todayChallengeLevelName &&
              g.game.gameNumber == challengeProgress.todayChallengeGameNumber)
          .firstOrNull,
      challengeProgress: challengeProgress,
      averageClearTimeSeconds: averageClearTimeSeconds,
    );
  }

  Future<List<ContinueGameSummary>> loadContinueGames({int? limit}) async {
    final savedGames = await _gameStateService.getSavedGames();
    if (savedGames.isEmpty) {
      return const [];
    }

    final summaries = <ContinueGameSummary>[];
    final targetCount = limit == null || limit <= 0 ? null : limit;
    final levelsByName = {
      for (final level in SudokuLevel.levels) level.name: level,
    };

    for (final saved in savedGames) {
      final session = saved.session;
      final level = levelsByName[saved.levelName] ?? SudokuLevel.levels.first;
      final entry = await _loadGameEntry(saved.levelName, saved.gameNumber);
      if (entry == null) {
        continue;
      }
      final board = entry['board'] as List<List<int>>;
      final solution = entry['solution'] as List<List<int>>;
      if (!_isPlayableBoard(board) || !_isPlayableBoard(solution)) {
        continue;
      }
      if (!_isPlayableBoard(session.board)) {
        continue;
      }
      final userFilledCells = _countUserFilledCells(
        originalBoard: board,
        savedBoard: session.board,
      );
      // 레벨 목록과 동일한 이어하기 기준: 입력·메모 흔적이 있는 미완료 세션만.
      if (!session.isResumable(
        userFilledCells: userFilledCells,
        emptyCells: 81 - board.expand((row) => row).where((v) => v != 0).length,
        maxWrongCount: SudokuGameFeaturePolicy.forLevel(level).maxWrongCount,
      )) {
        continue;
      }

      final game = SudokuGame(
        board: board,
        solution: solution,
        emptyCells: level.emptyCells,
        levelName: saved.levelName,
        gameNumber: saved.gameNumber,
      );

      summaries.add(ContinueGameSummary(
        level: level,
        game: game,
        progress: _calculateProgress(
          originalBoard: board,
          savedBoard: session.board,
        ),
        elapsedFilledCells: userFilledCells,
        lastPlayedAtMillis: saved.lastPlayedAtMillis,
        elapsedSeconds: session.elapsedSeconds,
        wrongCount: session.wrongCount,
        isMemoMode: session.isMemoMode,
        noteCount: _countNotes(session.notes),
      ));

      if (targetCount != null && summaries.length >= targetCount) {
        break;
      }
    }

    return summaries;
  }

  Future<SudokuGame?> _loadTodayChallenge({
    required String levelName,
    required int gameNumber,
  }) async {
    final level = SudokuLevel.levels.firstWhere(
      (l) => l.name == levelName,
      orElse: () => SudokuLevel.levels.first,
    );
    final entry = await _loadPlayableEntry(levelName, gameNumber);
    if (entry == null) return null;
    return _gameFromEntry(
      level: level,
      levelName: levelName,
      gameNumber: gameNumber,
      entry: entry,
    );
  }

  double _calculateProgress({
    required List<List<int>> originalBoard,
    required List<List<int>> savedBoard,
  }) {
    final totalToFill = 81 -
        originalBoard.expand((row) => row).where((value) => value != 0).length;
    if (totalToFill <= 0) {
      return 1.0;
    }

    final filledByUser = _countUserFilledCells(
      originalBoard: originalBoard,
      savedBoard: savedBoard,
    );
    return (filledByUser / totalToFill).clamp(0.0, 1.0);
  }

  int _countUserFilledCells({
    required List<List<int>> originalBoard,
    required List<List<int>> savedBoard,
  }) {
    int count = 0;
    for (int row = 0; row < originalBoard.length; row++) {
      for (int col = 0; col < originalBoard[row].length; col++) {
        if (originalBoard[row][col] == 0 && savedBoard[row][col] != 0) {
          count++;
        }
      }
    }
    return count;
  }

  int _countNotes(List<List<Set<int>>> notes) {
    int count = 0;
    for (final row in notes) {
      for (final cell in row) {
        count += cell.length;
      }
    }
    return count;
  }

  Future<Map<String, dynamic>?> _loadPlayableEntry(
    String levelName,
    int gameNumber,
  ) async {
    final entry = await _loadGameEntry(levelName, gameNumber);
    if (entry == null) {
      return null;
    }

    final board = entry['board'] as List<List<int>>?;
    final solution = entry['solution'] as List<List<int>>?;
    if (board == null || solution == null) {
      return null;
    }
    if (!_isPlayableBoard(board) || !_isPlayableBoard(solution)) {
      return null;
    }

    return entry;
  }

  SudokuGame _gameFromEntry({
    required SudokuLevel level,
    required String levelName,
    required int gameNumber,
    required Map<String, dynamic> entry,
  }) {
    return SudokuGame(
      board: entry['board'] as List<List<int>>,
      solution: entry['solution'] as List<List<int>>,
      emptyCells: level.emptyCells,
      levelName: levelName,
      gameNumber: gameNumber,
    );
  }

  bool _isPlayableBoard(List<List<int>> board) {
    if (board.length != 9) {
      return false;
    }
    for (final row in board) {
      if (row.length != 9) {
        return false;
      }
    }
    return true;
  }
}
