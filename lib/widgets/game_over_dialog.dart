import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/widgets/game_result_dialog_frame.dart';

/// 게임 오버 다이얼로그. 완료 다이얼로그와 같은 너비·여백·버튼 규칙을 쓴다.
/// 실패를 평가하거나 강한 색으로 강조하지 않고, 실제 횟수와 한도만 알린다.
class GameOverDialog extends StatefulWidget {
  final int wrongCount;
  final int maxWrongCount;
  final VoidCallback onRestart;
  final VoidCallback onGoToLevelSelection;

  const GameOverDialog({
    super.key,
    required this.wrongCount,
    required this.maxWrongCount,
    required this.onRestart,
    required this.onGoToLevelSelection,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> {
  bool _handled = false;

  VoidCallback _once(VoidCallback action) => () {
        if (_handled) return;
        _handled = true;
        action();
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return GameResultDialogFrame(
      body: [
        Text(
          l10n.gameOverTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.gameOverWrongLabel(widget.wrongCount, widget.maxWrongCount),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.gameOverMessage,
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 14, height: 1.4, color: cs.onSurfaceVariant),
        ),
      ],
      primaryLabel: l10n.gameRestartMenuTitle,
      onPrimary: _once(widget.onRestart),
      secondaryLabel: l10n.dialogBackToLevels,
      onSecondary: _once(widget.onGoToLevelSelection),
    );
  }
}
