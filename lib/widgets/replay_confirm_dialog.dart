import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/widgets/dialog_metrics.dart';
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
    final m = DialogMetrics.of(context);
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
      insetPadding: EdgeInsets.symmetric(horizontal: m.inset(24), vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m.size(24.0, 28.0)),
        side: BorderSide(color: colors.completedBorder),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: m.maxWidth(phone: 340, tablet: 440),
          maxHeight: m.maxHeight ?? double.infinity,
        ),
        child: SingleChildScrollView(
          padding: m.isTablet
              ? EdgeInsets.fromLTRB(
                  32,
                  m.compactHeight ? 24 : 32,
                  32,
                  m.compactHeight ? 24 : 16,
                )
              : const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: m.spacing(44.0, 52.0),
                    height: m.spacing(44.0, 52.0),
                    decoration: BoxDecoration(
                      color: colors.completedBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.replay_rounded,
                      size: m.spacing(24.0, 28.0),
                      color: colors.primaryPurple,
                    ),
                  ),
                ),
              ),
              SizedBox(height: m.spacing(16.0, 20.0)),
              Text(
                l10n.levelReplayTitle(widget.gameNumber),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: m.size(20.0, 24.0),
                  fontWeight: FontWeight.w800,
                  color: colors.primaryText,
                ),
              ),
              if (recordLine != null) ...[
                SizedBox(height: m.spacing(8.0, 10.0)),
                Text(
                  recordLine,
                  key: const Key('replay-dialog-best-record'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: m.size(14.0, 16.0),
                    fontWeight: FontWeight.w700,
                    color: colors.primaryPurple,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              SizedBox(height: m.spacing(10.0, 12.0)),
              SentenceText(
                l10n.levelReplayBody,
                style: TextStyle(
                  fontSize: m.size(14.0, 16.0),
                  height: 1.45,
                  color: colors.secondaryText,
                ),
              ),
              SizedBox(height: m.spacing(20.0, 24.0)),
              FilledButton(
                onPressed: () => _answer(true),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryPurple,
                  foregroundColor:
                      isDark ? const Color(0xFF1F1B3A) : Colors.white,
                  minimumSize: Size.fromHeight(m.size(48.0, 54.0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: TextStyle(
                    fontSize: m.size(16.0, 17.0),
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
                  textStyle: TextStyle(
                    fontSize: m.size(15.0, 16.0),
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
