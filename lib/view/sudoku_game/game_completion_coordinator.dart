import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_game_set.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/challenge/weekly_goal_service.dart';
import 'package:sudoku159/services/records/game_record_notifier.dart';
import 'package:sudoku159/services/records/game_record_service.dart';
import 'package:sudoku159/services/settings/notification_service.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

class GameCompletionData {
  const GameCompletionData({
    required this.isNewBestRecord,
    required this.challengeMessage,
    required this.nextGame,
    this.weeklyGoalMessage,
  });

  final bool isNewBestRecord;
  final String? challengeMessage;

  /// 이번 판으로 이번 주 목표를 **처음** 달성했을 때만 채워진다.
  final String? weeklyGoalMessage;
  final SudokuGame? nextGame;
}

class GameCompletionCoordinator {
  GameCompletionCoordinator({
    GameRecordService? gameRecordService,
    ChallengeProgressService? challengeProgressService,
    NotificationService? notificationService,
    DatabaseHelper? databaseHelper,
    WeeklyGoalService? weeklyGoalService,
  })  : _weeklyGoalService = weeklyGoalService ?? WeeklyGoalService(),
        _gameRecordService = gameRecordService ?? GameRecordService(),
        _challengeProgressService =
            challengeProgressService ?? ChallengeProgressService(),
        _notificationService = notificationService ?? NotificationService(),
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  final GameRecordService _gameRecordService;
  final ChallengeProgressService _challengeProgressService;
  final NotificationService _notificationService;
  final DatabaseHelper _databaseHelper;
  final WeeklyGoalService _weeklyGoalService;

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
    // 완료 이벤트, 최고 기록, 일일 도전 기록은 서로 독립적으로 시도한다: 하나가
    // 실패해도 나머지 저장은 계속하고, 결과창은 항상 보여줄 수 있도록 어떤
    // 예외도 밖으로 내보내지 않는다. 실패는 로그로 남긴다.
    try {
      await _databaseHelper.saveClearEvent(
        levelName: level.name,
        gameNumber: game.gameNumber,
        clearTime: clearTimeSeconds,
        wrongCount: wrongCount,
        hintsUsed: hintsUsed,
        autoNotesUsed: autoNotesUsed,
      );
    } catch (e) {
      AppLogger.error('완료 이벤트 저장 실패(계속 진행)', e);
    }

    var isNewBestRecord = false;
    try {
      final recordResult = await _gameRecordService.saveClearRecordIfBest(
        levelName: level.name,
        gameNumber: game.gameNumber,
        clearTime: clearTimeSeconds,
        wrongCount: wrongCount,
        hintsUsed: hintsUsed,
        autoNotesUsed: autoNotesUsed,
      );
      isNewBestRecord = recordResult.improvedPrevious;
    } catch (e) {
      AppLogger.error('최고 기록 저장 실패(계속 진행)', e);
    }

    String? challengeMessage;
    try {
      final attributionDay =
          await _challengeProgressService.resolveCompletionDay(
        levelName: level.name,
        gameNumber: game.gameNumber,
        challengeDate: challengeDate,
      );
      if (attributionDay != null) {
        final isNewDailyCompletion =
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
        // 기록이 실제로 저장된 뒤에만 "도전 완료" 문구를 보여준다.
        if (isNewDailyCompletion) {
          challengeMessage = l10n.challengeCompletedToday;
        }
      }
    } catch (e) {
      AppLogger.error('일일 도전 기록 저장 실패(계속 진행)', e);
    }
    // 이번 판으로 주간 목표를 처음 채웠다면 결과 화면에서 한 번만 축하한다.
    String? weeklyGoalMessage;
    try {
      final events = await _databaseHelper.getRecentClearEvents(limit: 365);
      if (await _weeklyGoalService.consumeCelebration(events)) {
        weeklyGoalMessage = l10n.gameResultWeeklyGoalAchieved;
      }
    } catch (e) {
      AppLogger.error('주간 목표 확인 실패(계속 진행)', e);
    }
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
      isNewBestRecord: isNewBestRecord,
      challengeMessage: challengeMessage,
      nextGame: nextGame,
      weeklyGoalMessage: weeklyGoalMessage,
    );
  }
}
