import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/achievement_service.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/game_state_service.dart';

/// 빠른 시작 행의 종류 (표시 문자열은 UI에서 로케일 매핑).
enum QuickStartKind { recommended, beginner, random }

class ContinueGameSummary {
  const ContinueGameSummary({
    required this.level,
    required this.game,
    required this.progress,
    required this.elapsedFilledCells,
    required this.lastPlayedAtMillis,
    required this.elapsedSeconds,
    required this.hintsRemaining,
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
  final int hintsRemaining;
  final int wrongCount;
  final bool isMemoMode;
  final int noteCount;
}

class QuickStartOption {
  const QuickStartOption({
    required this.kind,
    required this.level,
  });

  final QuickStartKind kind;
  final SudokuLevel level;
}

class HomeDashboardData {
  const HomeDashboardData({
    required this.continueGame,
    required this.continueGames,
    required this.todayChallenge,
    required this.quickStartOptions,
    required this.challengeProgress,
    required this.achievementSummary,
  });

  final ContinueGameSummary? continueGame;
  final List<ContinueGameSummary> continueGames;
  final SudokuGame todayChallenge;
  final List<QuickStartOption> quickStartOptions;
  final ChallengeProgressSummary challengeProgress;
  final AchievementSummary achievementSummary;
}

class HomeDashboardService {
  HomeDashboardService({
    DatabaseHelper? databaseHelper,
    GameStateService? gameStateService,
    ChallengeProgressService? challengeProgressService,
    AchievementService? achievementService,
    Future<List<List<int>>> Function(String levelName, int gameNumber)? loadGame,
    Future<List<List<int>>> Function(String levelName, int gameNumber)? loadSolution,
    Future<int> Function(String levelName)? loadGameCount,
  })  : _gameStateService = gameStateService ?? GameStateService(),
        _challengeProgressService =
            challengeProgressService ?? ChallengeProgressService(databaseHelper: databaseHelper),
        _achievementService =
            achievementService ?? AchievementService(databaseHelper: databaseHelper),
        _loadGame =
            loadGame ?? (databaseHelper ?? DatabaseHelper()).getGame,
        _loadSolution =
            loadSolution ?? (databaseHelper ?? DatabaseHelper()).getSolution,
        _loadGameCount =
            loadGameCount ?? (databaseHelper ?? DatabaseHelper()).getGameCount;

  final GameStateService _gameStateService;
  final ChallengeProgressService _challengeProgressService;
  final AchievementService _achievementService;
  final Future<List<List<int>>> Function(String levelName, int gameNumber)
      _loadGame;
  final Future<List<List<int>>> Function(String levelName, int gameNumber)
      _loadSolution;
  final Future<int> Function(String levelName) _loadGameCount;

  Future<HomeDashboardData> load(AppLocalizations l10n) async {
    final continueGames = await _loadContinueGames();
    final continueGame = continueGames.isEmpty ? null : continueGames.first;
    final todayChallenge = await _loadTodayChallenge();
    final quickStartOptions = _buildQuickStartOptions();
    final challengeProgress = await _challengeProgressService.load();
    final achievementSummary = await _achievementService.load(l10n);

    return HomeDashboardData(
      continueGame: continueGame,
      continueGames: continueGames,
      todayChallenge: todayChallenge,
      quickStartOptions: quickStartOptions,
      challengeProgress: challengeProgress,
      achievementSummary: achievementSummary,
    );
  }

  Future<List<ContinueGameSummary>> _loadContinueGames() async {
    final savedGames = await _gameStateService.getSavedGames();
    if (savedGames.isEmpty) {
      return const [];
    }

    final summaries = <ContinueGameSummary>[];

    for (final saved in savedGames) {
      final session = await _gameStateService.loadSession(
        levelName: saved.levelName,
        gameNumber: saved.gameNumber,
      );
      if (session == null) {
        continue;
      }
      final level = SudokuLevel.levels.firstWhere(
        (item) => item.name == saved.levelName,
        orElse: () => SudokuLevel.levels.first,
      );
      final board = await _loadGame(saved.levelName, saved.gameNumber);
      final solution = await _loadSolution(saved.levelName, saved.gameNumber);
      if (board.isEmpty || solution.isEmpty) {
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
        hintsRemaining: session.hintsRemaining,
        wrongCount: session.wrongCount,
        isMemoMode: session.isMemoMode,
        noteCount: _countNotes(session.notes),
      ));
    }

    return summaries;
  }

  Future<SudokuGame> _loadTodayChallenge() async {
    final levelIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays %
        SudokuLevel.levels.length;
    final level = SudokuLevel.levels[levelIndex];
    final gameCount = await _loadGameCount(level.name);
    final safeGameCount = gameCount == 0 ? 1 : gameCount;
    final gameNumber =
        (DateTime.now().difference(DateTime(2024, 1, 1)).inDays % safeGameCount) +
            1;

    final board = await _loadGame(level.name, gameNumber);
    final solution = await _loadSolution(level.name, gameNumber);

    return SudokuGame(
      board: board,
      solution: solution,
      emptyCells: level.emptyCells,
      levelName: level.name,
      gameNumber: gameNumber,
    );
  }

  List<QuickStartOption> _buildQuickStartOptions() {
    final recommendedLevel = _recommendedLevel();
    return [
      QuickStartOption(
        kind: QuickStartKind.recommended,
        level: recommendedLevel,
      ),
      QuickStartOption(
        kind: QuickStartKind.beginner,
        level: SudokuLevel.levels.first,
      ),
      QuickStartOption(
        kind: QuickStartKind.random,
        level: SudokuLevel.levels[(DateTime.now().millisecond) %
            SudokuLevel.levels.length],
      ),
    ];
  }

  SudokuLevel _recommendedLevel() {
    for (final level in SudokuLevel.levels) {
      if (level.clearedGames < 5) {
        return level;
      }
    }
    return SudokuLevel.levels[SudokuLevel.levels.length ~/ 2];
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
}
