import 'package:flutter/material.dart';
import 'package:sudoku159/widgets/game_over_dialog.dart';

class GameOverFlow {
  const GameOverFlow._();

  static void show({
    required BuildContext context,
    required int wrongCount,
    required int maxWrongCount,
    required Future<void> Function() onRestart,
    required Future<void> Function() onGoToLevelSelection,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return GameOverDialog(
          wrongCount: wrongCount,
          maxWrongCount: maxWrongCount,
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
}
