import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/achievement_service.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/utils/sudoku_generator.dart';

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
    required this.todayChallenge,
    required this.challengeProgress,
    required this.achievementSummary,
    required this.averageClearTimeSeconds,
  });

  final ContinueGameSummary? continueGame;
  final List<ContinueGameSummary> continueGames;
  final SudokuGame todayChallenge;
  final ChallengeProgressSummary challengeProgress;
  final AchievementSummary achievementSummary;
  final int averageClearTimeSeconds;
}

class HomeDashboardService {
  static const int defaultContinueGamesLimit = 3;

  HomeDashboardService({
    DatabaseHelper? databaseHelper,
    GameStateService? gameStateService,
    ChallengeProgressService? challengeProgressService,
    AchievementService? achievementService,
    Future<Map<String, dynamic>?> Function(String levelName, int gameNumber)?
        loadGameEntry,
    Future<List<Map<String, dynamic>>> Function(String levelName)?
        loadGameEntriesForLevel,
    Future<Map<String, dynamic>> Function()? loadOverallStatistics,
    Future<List<Map<String, dynamic>>> Function()? loadRecentRecords,
  })  : _gameStateService = gameStateService ?? GameStateService(),
        _challengeProgressService =
            challengeProgressService ??
                ChallengeProgressService(databaseHelper: databaseHelper),
        _achievementService =
            achievementService ?? AchievementService(databaseHelper: databaseHelper),
        _loadGameEntry =
            loadGameEntry ?? (databaseHelper ?? DatabaseHelper()).getGameEntry,
        _loadGameEntriesForLevel =
            loadGameEntriesForLevel ??
                (databaseHelper ?? DatabaseHelper()).getGameEntriesForLevel,
        _loadOverallStatistics =
            loadOverallStatistics ??
                (achievementService != null && databaseHelper == null
                    ? (() async => const <String, dynamic>{})
                    : (databaseHelper ?? DatabaseHelper()).getOverallStatistics),
        _loadRecentRecords =
            loadRecentRecords ??
                (achievementService != null && databaseHelper == null
                    ? (() async => const <Map<String, dynamic>>[])
                    : (() => (databaseHelper ?? DatabaseHelper()).getRecentClearRecords(limit: 10000)));

  final GameStateService _gameStateService;
  final ChallengeProgressService _challengeProgressService;
  final AchievementService _achievementService;
  final Future<Map<String, dynamic>?> Function(String levelName, int gameNumber)
      _loadGameEntry;
  final Future<List<Map<String, dynamic>>> Function(String levelName)
      _loadGameEntriesForLevel;
  final Future<Map<String, dynamic>> Function() _loadOverallStatistics;
  final Future<List<Map<String, dynamic>>> Function() _loadRecentRecords;

  Future<HomeDashboardData> load(
    AppLocalizations l10n, {
    int continueGamesLimit = defaultContinueGamesLimit,
  }) async {
    final continueGamesFuture = loadContinueGames(limit: continueGamesLimit);
    final overallStatisticsFuture = _loadOverallStatistics();
    final recentRecordsFuture = _loadRecentRecords();

    final continueGames = await continueGamesFuture;
    final continueGame = continueGames.isEmpty ? null : continueGames.first;
    final overallStatistics = await overallStatisticsFuture;
    final recentRecords = await recentRecordsFuture;
    final challengeProgress = await _challengeProgressService.load(
      recentRecords: recentRecords,
    );
    final achievementSummary = await _achievementService.loadFromData(
      l10n,
      overall: overallStatistics,
      records: recentRecords,
      progress: challengeProgress,
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
      todayChallenge: todayChallenge,
      challengeProgress: challengeProgress,
      achievementSummary: achievementSummary,
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

      final game = SudokuGame(
        board: board,
        solution: solution,
        emptyCells: level.emptyCells,
        levelName: saved.levelName,
        gameNumber: saved.gameNumber,
      );

      summaries.add(
        ContinueGameSummary(
        level: level,
        game: game,
        progress: _calculateProgress(
          originalBoard: board,
          savedBoard: session.board,
        ),
        elapsedFilledCells: _countUserFilledCells(
          originalBoard: board,
          savedBoard: session.board,
        ),
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

  Future<SudokuGame> _loadTodayChallenge({
    required String levelName,
    required int gameNumber,
  }) async {
    final level = SudokuLevel.levels.firstWhere(
      (l) => l.name == levelName,
      orElse: () => SudokuLevel.levels.first,
    );
    final directMatch = await _loadPlayableEntry(levelName, gameNumber);
    if (directMatch != null) {
      return _gameFromEntry(
        level: level,
        levelName: levelName,
        gameNumber: gameNumber,
        entry: directMatch,
      );
    }

    final sameLevelEntries = await _loadGameEntriesForLevel(levelName);
    final fallbackEntry = _firstPlayableEntry(sameLevelEntries);
    if (fallbackEntry != null) {
      final fallbackGameNumber = fallbackEntry['game_number'] as int? ?? gameNumber;
      return _gameFromEntry(
        level: level,
        levelName: levelName,
        gameNumber: fallbackGameNumber,
        entry: fallbackEntry,
      );
    }

    final emergencyBoard = SudokuGenerator.generateSudoku(level.emptyCells);
    final emergencySolution = SudokuGenerator.getSolution(emergencyBoard);
    return SudokuGame(
      board: emergencyBoard,
      solution: emergencySolution,
      emptyCells: level.emptyCells,
      levelName: levelName,
      gameNumber: gameNumber,
    );
  }

  double _calculateProgress({
    required List<List<int>> originalBoard,
    required List<List<int>> savedBoard,
  }) {
    final totalToFill = 81 -
        originalBoard
            .expand((row) => row)
            .where((value) => value != 0)
            .length;
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

  Map<String, dynamic>? _firstPlayableEntry(List<Map<String, dynamic>> entries) {
    for (final entry in entries) {
      final board = entry['board'] as List<List<int>>?;
      final solution = entry['solution'] as List<List<int>>?;
      if (board == null || solution == null) {
        continue;
      }
      if (_isPlayableBoard(board) && _isPlayableBoard(solution)) {
        return entry;
      }
    }
    return null;
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
