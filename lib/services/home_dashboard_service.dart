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
  });

  final SudokuLevel level;
  final SudokuGame game;
  final double progress;
  final int elapsedFilledCells;
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
    required this.todayChallenge,
    required this.quickStartOptions,
    required this.challengeProgress,
    required this.achievementSummary,
  });

  final ContinueGameSummary? continueGame;
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
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _gameStateService = gameStateService ?? GameStateService(),
        _challengeProgressService =
            challengeProgressService ?? ChallengeProgressService(databaseHelper: databaseHelper),
        _achievementService =
            achievementService ?? AchievementService(databaseHelper: databaseHelper);

  final DatabaseHelper _databaseHelper;
  final GameStateService _gameStateService;
  final ChallengeProgressService _challengeProgressService;
  final AchievementService _achievementService;

  Future<HomeDashboardData> load(AppLocalizations l10n) async {
    final continueGame = await _loadContinueGame();
    final todayChallenge = await _loadTodayChallenge();
    final quickStartOptions = _buildQuickStartOptions();
    final challengeProgress = await _challengeProgressService.load();
    final achievementSummary = await _achievementService.load(l10n);

    return HomeDashboardData(
      continueGame: continueGame,
      todayChallenge: todayChallenge,
      quickStartOptions: quickStartOptions,
      challengeProgress: challengeProgress,
      achievementSummary: achievementSummary,
    );
  }

  Future<ContinueGameSummary?> _loadContinueGame() async {
    final savedGames = await _gameStateService.getSavedGames();
    if (savedGames.isEmpty) {
      return null;
    }

    for (final saved in savedGames) {
      final level = SudokuLevel.levels.firstWhere(
        (item) => item.name == saved.levelName,
        orElse: () => SudokuLevel.levels.first,
      );
      final board = await _databaseHelper.getGame(saved.levelName, saved.gameNumber);
      final solution =
          await _databaseHelper.getSolution(saved.levelName, saved.gameNumber);
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

      return ContinueGameSummary(
        level: level,
        game: game,
        progress: _calculateProgress(
          originalBoard: board,
          savedBoard: saved.board,
        ),
        elapsedFilledCells: _countUserFilledCells(
          originalBoard: board,
          savedBoard: saved.board,
        ),
      );
    }

    return null;
  }

  Future<SudokuGame> _loadTodayChallenge() async {
    final levelIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays %
        SudokuLevel.levels.length;
    final level = SudokuLevel.levels[levelIndex];
    final gameCount = await _databaseHelper.getGameCount(level.name);
    final safeGameCount = gameCount == 0 ? 1 : gameCount;
    final gameNumber =
        (DateTime.now().difference(DateTime(2024, 1, 1)).inDays % safeGameCount) +
            1;

    final board = await _databaseHelper.getGame(level.name, gameNumber);
    final solution = await _databaseHelper.getSolution(level.name, gameNumber);

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
}
