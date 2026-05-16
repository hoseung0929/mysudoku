import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_game_set.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/services/challenge/achievement_service.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/records/game_record_notifier.dart';
import 'package:sudoku159/services/records/game_record_service.dart';
import 'package:sudoku159/services/settings/notification_service.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

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
    await _databaseHelper.saveClearEvent(
      levelName: level.name,
      gameNumber: game.gameNumber,
      clearTime: clearTimeSeconds,
      wrongCount: wrongCount,
    );
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

    GameRecordNotifier.instance.notifyChanged();

    try {
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
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('완료 알림 처리 실패(무시): $e');
      }
    }

    SudokuGame? nextGame;
    try {
      final nextGameNumber = await _databaseHelper.findFirstUnclearedGameNumberAfter(
        level.name,
        game.gameNumber,
      );
      if (nextGameNumber != null) {
        final gamesInLevel = await SudokuGameSet.create(level.name);
        nextGame = gamesInLevel.where((g) => g.gameNumber == nextGameNumber).firstOrNull;
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('다음 퍼즐 계산 실패(무시): $e');
      }
      nextGame = null;
    }

    return GameCompletionData(
      isNewBestRecord: isNewBestRecord,
      newlyUnlockedBadges: newlyUnlockedBadges,
      challengeMessage: isTodayChallenge ? l10n.challengeCompletedToday : null,
      nextGame: nextGame,
    );
  }
}
