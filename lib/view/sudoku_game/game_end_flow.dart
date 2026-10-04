import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/sudoku_game/game_completion_coordinator.dart';
import 'package:sudoku159/view/sudoku_game/game_over_flow.dart';
import 'package:sudoku159/view/sudoku_game/notification_opt_in_flow.dart';
import 'package:sudoku159/widgets/game_complete_dialog.dart';

class GameEndFlow {
  GameEndFlow({
    GameCompletionCoordinator? completionCoordinator,
    NotificationOptInFlow? notificationOptInFlow,
  })  : _completionCoordinator =
            completionCoordinator ?? GameCompletionCoordinator(),
        _notificationOptInFlow =
            notificationOptInFlow ?? NotificationOptInFlow();

  final GameCompletionCoordinator _completionCoordinator;
  final NotificationOptInFlow _notificationOptInFlow;

  Future<void> showCompletion({
    required BuildContext context,
    required SudokuLevel level,
    required SudokuGame game,
    required int clearTimeSeconds,
    required int wrongCount,
    required int hintsUsed,
    bool autoNotesUsed = false,
    String? challengeDate,
    bool challengeCountsForStreak = true,
    required Future<void> Function() onRestart,
    required Future<void> Function() onGoToLevelSelection,
    required Future<void> Function(SudokuGame nextGame) onNextPuzzle,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    // 최종 방어선: 기록 저장이 어떤 이유로든 예외를 내도 결과창은 반드시
    // 보여준다(기본 결과로 대체).
    GameCompletionData completionData;
    try {
      completionData = await _completionCoordinator.prepare(
        l10n: l10n,
        level: level,
        game: game,
        clearTimeSeconds: clearTimeSeconds,
        wrongCount: wrongCount,
        hintsUsed: hintsUsed,
        autoNotesUsed: autoNotesUsed,
        challengeDate: challengeDate,
        challengeCountsForStreak: challengeCountsForStreak,
      );
    } catch (e) {
      AppLogger.error('완료 처리 준비 실패(기본 결과로 결과창 표시)', e);
      completionData = const GameCompletionData(
        isNewBestRecord: false,
        challengeMessage: null,
        nextGame: null,
      );
    }
    if (!context.mounted) return;

    // 완료 기록은 위에서 이미 저장됐다. 결과창을 닫은 뒤, 다음 화면으로
    // 이동하기 전에 첫 완료 알림 안내를 한 번만 보여 준다. 알림 처리가
    // 실패해도 사용자가 고른 이동은 반드시 실행한다.
    Future<void> closeResultThen(Future<void> Function() action) async {
      try {
        await Future<void>.delayed(Duration.zero);
        if (context.mounted) {
          await _notificationOptInFlow.maybeShow(context);
        }
      } catch (e) {
        if (kDebugMode) {
          AppLogger.debug('완료 후 알림 안내 실패(이동은 계속): $e');
        }
      } finally {
        await action();
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return GameCompleteDialog(
          levelLabel:
              '${level.localizedName(l10n)} · ${l10n.gameNumberLabel(game.gameNumber)}',
          hintsUsed: hintsUsed,
          timeInSeconds: clearTimeSeconds,
          wrongCount: wrongCount,
          isNewBestRecord: completionData.isNewBestRecord,
          challengeMessage: completionData.challengeMessage,
          weeklyGoalMessage: completionData.weeklyGoalMessage,
          onNextPuzzle: completionData.nextGame == null
              ? null
              : () async {
                  Navigator.of(dialogContext).pop();
                  await closeResultThen(
                    () => onNextPuzzle(completionData.nextGame!),
                  );
                },
          onRestart: () async {
            Navigator.of(dialogContext).pop();
            await closeResultThen(onRestart);
          },
          onGoToLevelSelection: () async {
            Navigator.of(dialogContext).pop();
            await closeResultThen(onGoToLevelSelection);
          },
        );
      },
    );
  }

  void showGameOver({
    required BuildContext context,
    required int wrongCount,
    required int maxWrongCount,
    required Future<void> Function() onRestart,
    required Future<void> Function() onGoToLevelSelection,
  }) {
    GameOverFlow.show(
      context: context,
      wrongCount: wrongCount,
      maxWrongCount: maxWrongCount,
      onRestart: onRestart,
      onGoToLevelSelection: onGoToLevelSelection,
    );
  }
}
