import 'package:flutter/material.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/view/sudoku_game/game_completion_coordinator.dart';
import 'package:mysudoku/view/sudoku_game/game_over_flow.dart';
import 'package:mysudoku/view/settings_screen.dart';
import 'package:mysudoku/widgets/game_complete_dialog.dart';

class GameEndFlow {
  GameEndFlow({
    GameCompletionCoordinator? completionCoordinator,
  }) : _completionCoordinator =
            completionCoordinator ?? GameCompletionCoordinator();

  final GameCompletionCoordinator _completionCoordinator;

  Future<void> showCompletion({
    required BuildContext context,
    required SudokuLevel level,
    required SudokuGame game,
    required int clearTimeSeconds,
    required int wrongCount,
    required Future<void> Function() onRestart,
    required Future<void> Function() onGoToLevelSelection,
    required Future<void> Function(SudokuGame nextGame) onNextPuzzle,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final completionData = await _completionCoordinator.prepare(
      l10n: l10n,
      level: level,
      game: game,
      clearTimeSeconds: clearTimeSeconds,
      wrongCount: wrongCount,
    );
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return GameCompleteDialog(
          timeInSeconds: clearTimeSeconds,
          wrongCount: wrongCount,
          isNewBestRecord: completionData.isNewBestRecord,
          challengeMessage: completionData.challengeMessage,
          onOpenSettings: () async {
            Navigator.of(dialogContext).pop();
            await Future<void>.delayed(Duration.zero);
            if (!context.mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
          onNextPuzzle: completionData.nextGame == null
              ? null
              : () async {
                  Navigator.of(dialogContext).pop();
                  await Future<void>.delayed(Duration.zero);
                  await onNextPuzzle(completionData.nextGame!);
                },
          onRestart: () async {
            Navigator.of(dialogContext).pop();
            await onRestart();
          },
          onGoToLevelSelection: () async {
            Navigator.of(dialogContext).pop();
            await onGoToLevelSelection();
          },
        );
      },
    );
  }

  void showGameOver({
    required BuildContext context,
    required int wrongCount,
    required Future<void> Function() onRestart,
    required Future<void> Function() onGoToLevelSelection,
  }) {
    GameOverFlow.show(
      context: context,
      wrongCount: wrongCount,
      onRestart: onRestart,
      onGoToLevelSelection: onGoToLevelSelection,
    );
  }
}
