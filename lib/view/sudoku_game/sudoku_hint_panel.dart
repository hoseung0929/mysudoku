import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/app_colors.dart';
import 'package:sudoku159/utils/sudoku_hint_finder.dart';

/// 숫자패드 자리에 겹쳐 보여 주는 2단계 힌트 설명.
/// 1단계: 살펴볼 곳만 알려 준다. 2단계: 기법 이름과 이유를 설명한다.
/// 어느 단계에서든 정답을 바로 넣을 수 있다.
class SudokuHintPanel extends StatelessWidget {
  const SudokuHintPanel({
    super.key,
    required this.hint,
    required this.step,
    required this.onNext,
    required this.onFill,
    required this.onClose,
  });

  final SudokuHint hint;
  final int step;
  final VoidCallback onNext;
  final VoidCallback onFill;
  final VoidCallback onClose;

  static const Duration _stepTransitionDuration = Duration(milliseconds: 170);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stepDuration = reduceMotion ? Duration.zero : _stepTransitionDuration;
    final isLookStep = step == 1;
    final title = isLookStep ? l10n.hintStepLookTitle : _techniqueName(l10n);
    final body = isLookStep
        ? [
            if (hint.movedFromSelection) l10n.hintMovedFromSelection,
            _lookText(l10n),
          ].join(' ')
        : _explainText(l10n);

    return Container(
      key: const ValueKey('sudoku-hint-panel'),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final header = _buildHeader(context, l10n, title, stepDuration);
          final bodyText = Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _stepSwitcher(
              duration: stepDuration,
              keyValue: 'hint-body-$step',
              child: Text(
                body,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  height: 1.4,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          );
          final actions = Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: _stepSwitcher(
              duration: stepDuration,
              keyValue: 'hint-actions-$step',
              child: _buildActions(l10n, isLookStep),
            ),
          );
          const padding = EdgeInsets.fromLTRB(16, 4, 8, 12);

          // 높이가 넉넉하면 버튼을 아래에 고정하고 설명만 스크롤한다. 작은
          // 화면·큰 글씨에서는 전체를 스크롤해 어느 요소도 잘리지 않게 한다.
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final canPinActions =
              constraints.maxHeight >= 120 * textScale.clamp(1.0, 3.0);
          if (canPinActions) {
            return Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Expanded(child: SingleChildScrollView(child: bodyText)),
                  actions,
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, bodyText, actions],
            ),
          );
        },
      ),
    );
  }

  /// 1↔2단계 전환 시 제목/본문/버튼만 짧게 크로스페이드한다(아이콘·닫기
  /// 버튼은 그대로 유지). 최대 4px 아래에서 올라오는 정도만 허용한다.
  Widget _stepSwitcher({
    required Duration duration,
    required String keyValue,
    required Widget child,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (transitionChild, animation) {
        if (duration == Duration.zero) {
          return FadeTransition(opacity: animation, child: transitionChild);
        }
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, builtChild) =>
                animation.status == AnimationStatus.reverse
                    ? builtChild!
                    : Transform.translate(
                        offset: Offset(0, (1 - animation.value) * 4),
                        child: builtChild,
                      ),
            child: transitionChild,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(keyValue), child: child),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    String title,
    Duration stepDuration,
  ) {
    return Row(
      children: [
        const Icon(
          Icons.lightbulb_outline,
          size: 20,
          color: Color(0xFFE0A526),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            header: true,
            child: _stepSwitcher(
              duration: stepDuration,
              keyValue: 'hint-title-$step',
              child: Text(
                title,
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.hintClose,
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          iconSize: 20,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }

  Widget _buildActions(AppLocalizations l10n, bool isLookStep) {
    if (!isLookStep) {
      return FilledButton(
        onPressed: onFill,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
        child: Text(l10n.hintFillAnswer),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onFill,
            style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(l10n.hintFillAnswer, textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(l10n.hintNextStep, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  String _techniqueName(AppLocalizations l10n) {
    return switch (hint.technique) {
      SudokuHintTechnique.nakedSingle => l10n.hintTechniqueNakedSingle,
      SudokuHintTechnique.hiddenSingleBox ||
      SudokuHintTechnique.hiddenSingleRow ||
      SudokuHintTechnique.hiddenSingleCol =>
        l10n.hintTechniqueHiddenSingle,
      SudokuHintTechnique.reveal => l10n.hintTechniqueReveal,
    };
  }

  String _lookText(AppLocalizations l10n) {
    return switch (hint.technique) {
      SudokuHintTechnique.hiddenSingleBox => l10n.hintLookBox(hint.value),
      SudokuHintTechnique.hiddenSingleRow => l10n.hintLookRow(hint.value),
      SudokuHintTechnique.hiddenSingleCol => l10n.hintLookCol(hint.value),
      SudokuHintTechnique.nakedSingle ||
      SudokuHintTechnique.reveal =>
        l10n.hintLookCell,
    };
  }

  String _explainText(AppLocalizations l10n) {
    return switch (hint.technique) {
      SudokuHintTechnique.nakedSingle =>
        l10n.hintExplainNakedSingle(hint.value),
      SudokuHintTechnique.hiddenSingleBox =>
        l10n.hintExplainHiddenSingleBox(hint.value),
      SudokuHintTechnique.hiddenSingleRow =>
        l10n.hintExplainHiddenSingleRow(hint.value),
      SudokuHintTechnique.hiddenSingleCol =>
        l10n.hintExplainHiddenSingleCol(hint.value),
      SudokuHintTechnique.reveal => l10n.hintExplainReveal,
    };
  }
}
