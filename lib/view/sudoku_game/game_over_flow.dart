import 'package:flutter/material.dart';
import 'package:mysudoku/widgets/game_over_dialog.dart';

class GameOverFlow {
  const GameOverFlow._();

  static void show({
    required BuildContext context,
    required int wrongCount,
    required Future<void> Function() onRestart,
    required Future<void> Function() onGoToLevelSelection,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return GameOverDialog(
          wrongCount: wrongCount,
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
