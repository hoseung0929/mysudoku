import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/utils/time_format.dart';
import 'package:sudoku159/widgets/mascot_image.dart';
import 'package:sudoku159/widgets/game_result_dialog_frame.dart';

/// 게임 완료 다이얼로그.
///
/// 위에서 아래로: 작은 축하 이미지 → 제목 → 난이도·번호 → 시간·실수 카드 →
/// (조건부) 힌트 → 성취 메시지(최대 두 줄: 도전/최고 기록 + 주간 목표) →
/// 주요 버튼 → 보조 버튼. 같은 값을 문장으로 한 번 더 풀어 쓰지 않는다.
class GameCompleteDialog extends StatefulWidget {
  const GameCompleteDialog({
    super.key,
    required this.levelLabel,
    required this.timeInSeconds,
    required this.wrongCount,
    this.isNewBestRecord = false,
    this.challengeMessage,
    this.weeklyGoalMessage,
    required this.onRestart,
    required this.onGoToLevelSelection,
    this.onNextPuzzle,
  });

  /// "중급 · 게임 18"처럼 이미 지역화된 난이도·문제 번호.
  final String levelLabel;
  final int timeInSeconds;
  final int wrongCount;

  final bool isNewBestRecord;
  final String? challengeMessage;

  /// 이번 주 목표를 처음 달성한 판에서만 전달한다(짧은 축하 한 줄).
  final String? weeklyGoalMessage;
  final VoidCallback onRestart;
  final VoidCallback onGoToLevelSelection;

  /// 실제로 시작할 수 있는 다음 퍼즐이 있을 때만 전달한다.
  final VoidCallback? onNextPuzzle;

  String get formattedTime => formatElapsedSeconds(timeInSeconds);

  @override
  State<GameCompleteDialog> createState() => _GameCompleteDialogState();
}

class _GameCompleteDialogState extends State<GameCompleteDialog> {
  // 빠르게 반복해서 눌러도 화면 이동/팝이 한 번만 일어나게 한다.
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
    final hasNext = widget.onNextPuzzle != null;

    // 성취 메시지는 최대 한 개: 오늘의 도전 완료 > 새 최고 기록.
    final achievement = widget.challengeMessage ??
        (widget.isNewBestRecord ? l10n.dialogNewBestMessage : null);

    return GameResultDialogFrame(
      header: const _CelebrationHeader(),
      body: [
        Text(
          l10n.dialogPuzzleCompleteTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          widget.levelLabel,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        _ResultSummary(
          timeLabel: l10n.dialogElapsedTime,
          timeValue: widget.formattedTime,
          mistakesLabel: l10n.dialogWrongCount,
          mistakesValue: l10n.dialogWrongCountValue(widget.wrongCount),
        ),
        if (achievement != null) ...[
          const SizedBox(height: 12),
          Text(
            achievement,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
        if (widget.weeklyGoalMessage != null) ...[
          const SizedBox(height: 10),
          _WeeklyGoalCelebration(message: widget.weeklyGoalMessage!),
        ],
      ],
      primaryLabel: hasNext ? l10n.dialogNextPuzzle : l10n.dialogBackToLevels,
      onPrimary: _once(
        hasNext ? widget.onNextPuzzle! : widget.onGoToLevelSelection,
      ),
      secondaryLabel:
          hasNext ? l10n.dialogBackToLevels : l10n.dialogSolveSameAgain,
      onSecondary: _once(
        hasNext ? widget.onGoToLevelSelection : widget.onRestart,
      ),
    );
  }
}

/// 시간·실수 두 항목을 한 덩어리(옅은 배경)에 같은 너비 2열로 표시한다.
/// 큰 글씨로 두 열이 들어가지 않으면 세로로 전환한다.
class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.timeLabel,
    required this.timeValue,
    required this.mistakesLabel,
    required this.mistakesValue,
  });

  final String timeLabel;
  final String timeValue;
  final String mistakesLabel;
  final String mistakesValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stacked = MediaQuery.textScalerOf(context).scale(1.0) > 1.3;

    Widget item(String label, String value) => Semantics(
          container: true,
          label: '$label $value',
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: stacked
          ? Column(
              children: [
                item(timeLabel, timeValue),
                Divider(height: 24, color: cs.outlineVariant),
                item(mistakesLabel, mistakesValue),
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: Center(child: item(timeLabel, timeValue))),
                  VerticalDivider(width: 1, color: cs.outlineVariant),
                  Expanded(
                    child: Center(child: item(mistakesLabel, mistakesValue)),
                  ),
                ],
              ),
            ),
    );
  }
}

/// 완료 축하 그래픽: 왕관과 별 메달을 든 펭귄 + 정적 반짝임 3개.
/// 글씨가 아주 크면 본문(제목·결과)과 버튼이 밀려나지 않도록 생략한다.
///
/// 결과창 인스턴스당 한 번, 캐릭터만 280ms 동안 나타난다(투명도 0→1,
/// 크기 0.94→1.0). 자리는 처음부터 확보되어 레이아웃이 움직이지 않고,
/// 동작 줄이기에서는 바로 최종 상태로 보인다.
class _CelebrationHeader extends StatefulWidget {
  const _CelebrationHeader();

  @override
  State<_CelebrationHeader> createState() => _CelebrationHeaderState();
}

class _CelebrationHeaderState extends State<_CelebrationHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1.0) > 1.6) {
      return const SizedBox.shrink();
    }
    final gold = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE8B84A)
        : const Color(0xFFF0AE2E);
    // 큰 화면에서도 그림을 키우지 않는다.
    const size = 104.0;
    return ExcludeSemantics(
      child: SizedBox(
        width: size + 40,
        height: size,
        child: FadeTransition(
          opacity: _curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(_curve),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const MascotImage(asset: MascotImage.celebrate, size: size),
                Positioned(
                  left: 4,
                  top: 10,
                  child:
                      Icon(Icons.auto_awesome_rounded, size: 20, color: gold),
                ),
                Positioned(
                  right: 6,
                  top: 4,
                  child: Icon(Icons.star_rounded, size: 14, color: gold),
                ),
                Positioned(
                  right: 0,
                  top: size * 0.5,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: gold.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 이번 주 목표를 처음 달성한 결과 화면에서만 보이는 짧은 축하 한 줄. 체크가
/// 살짝 커지며 나타난다(동작 줄이기에서는 바로 표시).
class _WeeklyGoalCelebration extends StatelessWidget {
  const _WeeklyGoalCelebration({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 흰 배경에서 14px 글자로 읽히도록 대비를 확보한 초록(약 5:1).
    final color = isDark ? const Color(0xFF5BC79A) : const Color(0xFF2E7D5B);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      key: const Key('weekly_goal_celebration'),
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
