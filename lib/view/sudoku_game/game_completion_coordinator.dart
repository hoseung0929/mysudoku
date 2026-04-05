import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_game_set.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/services/achievement_service.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/game_record_service.dart';
import 'package:mysudoku/services/notification_service.dart';

class GameCompletionData {
  const GameCompletionData({
    required this.isNewBestRecord,
    required this.newlyUnlockedBadges,
    required this.challengeMessage,
    required this.nextGame,
  });

  final bool isNewBestRecord;
  final List<AchievementBadge> newlyUnlockedBadges;
  final String? challengeMessage;
  final SudokuGame? nextGame;
}

class GameCompletionCoordinator {
  GameCompletionCoordinator({
    GameRecordService? gameRecordService,
    ChallengeProgressService? challengeProgressService,
    AchievementService? achievementService,
    NotificationService? notificationService,
    DatabaseHelper? databaseHelper,
  })  : _gameRecordService = gameRecordService ?? GameRecordService(),
        _challengeProgressService =
            challengeProgressService ?? ChallengeProgressService(),
        _achievementService = achievementService ?? AchievementService(),
        _notificationService = notificationService ?? NotificationService(),
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  final GameRecordService _gameRecordService;
  final ChallengeProgressService _challengeProgressService;
  final AchievementService _achievementService;
  final NotificationService _notificationService;
  final DatabaseHelper _databaseHelper;

  Future<GameCompletionData> prepare({
    required AppLocalizations l10n,
    required SudokuLevel level,
    required SudokuGame game,
    required int clearTimeSeconds,
    required int wrongCount,
  }) async {
    final challengeBefore = await _challengeProgressService.load();
    final beforeAchievements = await _achievementService.load(l10n);
    final isNewBestRecord = await _gameRecordService.saveClearRecordIfBest(
      levelName: level.name,
      gameNumber: game.gameNumber,
      clearTime: clearTimeSeconds,
      wrongCount: wrongCount,
    );
    final isTodayChallenge = await _challengeProgressService.isTodayChallenge(
      levelName: level.name,
      gameNumber: game.gameNumber,
    );
    if (isTodayChallenge) {
      await _databaseHelper.recordDailyChallengeCompletion(DateTime.now());
    }
    final afterAchievements = await _achievementService.load(l10n);
    final newlyUnlockedBadges = _achievementService.getNewlyUnlockedBadges(
      before: beforeAchievements,
      after: afterAchievements,
    );
    final challengeAfter = await _challengeProgressService.load();

    await _notificationService.showGameCompleteNotification(
      levelName: level.name,
      gameNumber: game.gameNumber,
      isNewBestRecord: isNewBestRecord,
    );
    if (!challengeBefore.isWeeklyGoalAchieved &&
        challengeAfter.isWeeklyGoalAchieved) {
      await _notificationService.showDailyGoalAchievedNotification(
        weeklyClearCount: challengeAfter.weeklyClearCount,
        weeklyGoalTarget: challengeAfter.weeklyGoalTarget,
      );
    }
    if (isTodayChallenge) {
      await _notificationService.resyncFromStoredSettings();
    }

    final gamesInLevel = await SudokuGameSet.create(level.name);
    gamesInLevel.sort((a, b) => a.gameNumber.compareTo(b.gameNumber));
    final currentIndex = gamesInLevel.indexWhere(
      (candidate) => candidate.gameNumber == game.gameNumber,
    );
    final nextGame = currentIndex >= 0 && currentIndex < gamesInLevel.length - 1
        ? gamesInLevel[currentIndex + 1]
        : null;

    return GameCompletionData(
      isNewBestRecord: isNewBestRecord,
      newlyUnlockedBadges: newlyUnlockedBadges,
      challengeMessage: isTodayChallenge ? l10n.challengeCompletedToday : null,
      nextGame: nextGame,
    );
  }
}
