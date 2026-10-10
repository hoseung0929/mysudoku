import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/utils/time_format.dart';
import 'package:sudoku159/widgets/sentence_text.dart';

/// 이미 완료한 퍼즐을 처음부터 다시 풀지 묻는 확인창. 확인하면 true, 취소·바깥
/// 터치·뒤로가기는 false/null이다(퍼즐 선택 화면과 기록 화면이 함께 쓴다).
/// [bestRecord]는 그 퍼즐의 `clear_records` 행으로, 있으면 제목 아래에 최고
/// 기록(시간·실수·힌트)을 한 줄로 보여 준다.
Future<bool?> showReplayConfirmDialog(
  BuildContext context, {
  required int gameNumber,
  Map<String, dynamic>? bestRecord,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration:
        reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, _, __) =>
        _ReplayConfirmDialog(gameNumber: gameNumber, bestRecord: bestRecord),
    transitionBuilder: (context, animation, _, child) {
      if (reduceMotion) return child;
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ReplayConfirmDialog extends StatefulWidget {
  const _ReplayConfirmDialog({required this.gameNumber, this.bestRecord});

  final int gameNumber;
  final Map<String, dynamic>? bestRecord;

  @override
  State<_ReplayConfirmDialog> createState() => _ReplayConfirmDialogState();
}

class _ReplayConfirmDialogState extends State<_ReplayConfirmDialog> {
  bool _answered = false;

  void _answer(bool value) {
    // 연타로 화면 전환이 두 번 일어나지 않게 첫 응답만 받는다.
    if (_answered) return;
    _answered = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LevelStatusPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final record = widget.bestRecord;
    final int? bestTime = (record?['clear_time'] as num?)?.toInt();
    final String? recordLine = bestTime == null
        ? null
        : [
            '${l10n.recordsSectionBestRecordTitle} '
                '${formatElapsedSeconds(bestTime)}',
            l10n.recordsTimelineMistakesValue(
                (record!['wrong_count'] as num?)?.toInt() ?? 0),
            if (((record['hints_used'] as num?)?.toInt() ?? 0) > 0)
              l10n.dialogHintsUsed((record['hints_used'] as num).toInt()),
          ].join(' · ');
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.completedBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.completedBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.replay_rounded,
                      size: 24,
                      color: colors.primaryPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.levelReplayTitle(widget.gameNumber),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryText,
                ),
              ),
              if (recordLine != null) ...[
                const SizedBox(height: 8),
                Text(
                  recordLine,
                  key: const Key('replay-dialog-best-record'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.primaryPurple,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SentenceText(
                l10n.levelReplayBody,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _answer(true),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryPurple,
                  foregroundColor:
                      isDark ? const Color(0xFF1F1B3A) : Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child:
                    Text(l10n.levelReplayConfirm, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _answer(false),
                style: TextButton.styleFrom(
                  foregroundColor: colors.secondaryText,
                  minimumSize: const Size.fromHeight(44),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
