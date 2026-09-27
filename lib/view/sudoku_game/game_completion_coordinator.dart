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
    required int hintsUsed,
    bool autoNotesUsed = false,
    String? challengeDate,
    bool challengeCountsForStreak = true,
  }) async {
    final beforeAchievements = await _achievementService.load(l10n);
    await _databaseHelper.saveClearEvent(
      levelName: level.name,
      gameNumber: game.gameNumber,
      clearTime: clearTimeSeconds,
      wrongCount: wrongCount,
      hintsUsed: hintsUsed,
      autoNotesUsed: autoNotesUsed,
    );
    final recordResult = await _gameRecordService.saveClearRecordIfBest(
      levelName: level.name,
      gameNumber: game.gameNumber,
      clearTime: clearTimeSeconds,
      wrongCount: wrongCount,
      hintsUsed: hintsUsed,
      autoNotesUsed: autoNotesUsed,
    );
    final attributionDay = await _challengeProgressService.resolveCompletionDay(
      levelName: level.name,
      gameNumber: game.gameNumber,
      challengeDate: challengeDate,
    );
    var isNewDailyCompletion = false;
    if (attributionDay != null) {
      isNewDailyCompletion =
          !await _databaseHelper.hasDailyChallengeCompletionForDate(
        ChallengeProgressService.formatLocalDate(attributionDay),
      );
      // 같은 날짜의 재도전은 더 좋은 결과일 때만 세부 기록을 갱신한다.
      await _databaseHelper.recordDailyChallengeCompletion(
        attributionDay,
        levelName: level.name,
        gameNumber: game.gameNumber,
        clearTime: clearTimeSeconds,
        wrongCount: wrongCount,
        hintsUsed: hintsUsed,
        autoNotesUsed: autoNotesUsed,
        streakEligible: challengeCountsForStreak,
      );
    }
    final afterAchievements = await _achievementService.load(l10n);
    final newlyUnlockedBadges = _achievementService.getNewlyUnlockedBadges(
      before: beforeAchievements,
      after: afterAchievements,
    );

    GameRecordNotifier.instance.notifyChanged();

    try {
      await _notificationService.syncReminders();
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('알림 재동기화 실패(무시): $e');
      }
    }

    SudokuGame? nextGame;
    try {
      final nextGameNumber =
          await _databaseHelper.findFirstUnclearedGameNumberAfter(
        level.name,
        game.gameNumber,
      );
      if (nextGameNumber != null) {
        final gamesInLevel = await SudokuGameSet.create(level.name);
        nextGame = gamesInLevel
            .where((g) => g.gameNumber == nextGameNumber)
            .firstOrNull;
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('다음 퍼즐 계산 실패(무시): $e');
      }
      nextGame = null;
    }

    return GameCompletionData(
      isNewBestRecord: recordResult.improvedPrevious,
      newlyUnlockedBadges: newlyUnlockedBadges,
      challengeMessage:
          isNewDailyCompletion ? l10n.challengeCompletedToday : null,
      nextGame: nextGame,
    );
  }
}
