import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sudoku159/presenter/game/pencil_input_controller.dart';

/// 필기 대상 셀에 그려 주는 시각 상태(보드 위 오버레이용).
class PencilCellFeedback {
  const PencilCellFeedback({
    required this.row,
    required this.col,
    required this.phase,
    this.previewDigit,
  });

  final int row;
  final int col;
  final PencilCellPhase phase;
  final int? previewDigit;
}

/// 필기 대상 셀의 상태 표시: 필기 대기/중은 라벤더 배경 + 2px 보라 테두리,
/// 인식 중은 작은 진행 표시, 성공은 반투명 숫자 미리 보기, 실패는 짧은 흔들림과
/// 붉은 테두리. 색만으로 구분하지 않도록 실패에는 ×, 인식 중에는 진행 표시를 둔다.
class PencilCellFeedbackOverlay extends StatelessWidget {
  const PencilCellFeedbackOverlay({
    super.key,
    required this.feedback,
    required this.cellExtent,
    required this.accent,
    required this.errorColor,
    required this.reduceMotion,
  });

  final PencilCellFeedback feedback;
  final double cellExtent;
  final Color accent;
  final Color errorColor;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final isError = feedback.phase == PencilCellPhase.error;
    final color = isError ? errorColor : accent;
    final Widget content;
    switch (feedback.phase) {
      case PencilCellPhase.recognizing:
        content = Center(
          child: SizedBox(
            width: cellExtent * 0.28,
            height: cellExtent * 0.28,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
        );
      case PencilCellPhase.recognized:
        content = Center(
          child: Opacity(
            opacity: 0.5,
            child: Text(
              '${feedback.previewDigit ?? ''}',
              style: TextStyle(
                fontSize: (cellExtent * 0.62).clamp(18.0, 34.0),
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        );
      case PencilCellPhase.error:
        content = Center(
          child: Icon(Icons.close_rounded,
              size: cellExtent * 0.42, color: errorColor),
        );
      default:
        content = const SizedBox.shrink();
    }

    final box = Container(
      width: cellExtent,
      height: cellExtent,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isError ? 0.08 : 0.14),
        border: Border.all(color: color, width: 2),
      ),
      child: content,
    );

    final Widget animated = isError && !reduceMotion
        ? TweenAnimationBuilder<double>(
            key: ValueKey('pencil-error-${feedback.row}-${feedback.col}'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 280),
            builder: (context, t, child) => Transform.translate(
              offset: Offset(
                (1 - t) * 6 * (((t * 6).floor() % 2) == 0 ? 1 : -1),
                0,
              ),
              child: child,
            ),
            child: box,
          )
        : box;

    return Positioned(
      left: feedback.col * cellExtent,
      top: feedback.row * cellExtent,
      width: cellExtent,
      height: cellExtent,
      child: IgnorePointer(child: animated),
    );
  }
}

/// 선택된 셀 위에 정확히 겹치는, 눈에 안 보이는 필기 입력 필드.
///
/// 아이패드 애플펜슬로 이 영역 위에 직접 숫자를 쓰면 iPadOS의 Scribble이
/// 알아서 인식해서 텍스트로 넣어준다 — 별도 "펜슬 모드" 없이 손가락 탭(기존
/// 넘패드)과 항상 같이 켜져 있다. 소프트 키보드는 [TextInputType.none]으로
/// 억제하고, 인식된 값은 화면에 직접 그리지 않으므로(텍스트/커서 색 투명)
/// 보드가 이미 그리는 숫자와 중복 렌더링되지 않는다.
class SudokuPencilInputOverlay extends StatefulWidget {
  const SudokuPencilInputOverlay({
    super.key,
    required this.selectedRow,
    required this.selectedCol,
    required this.cellExtent,
    required this.onDigitEntered,
    this.onTextEntered,
  });

  final int? selectedRow;
  final int? selectedCol;
  final double cellExtent;
  final void Function(int digit) onDigitEntered;

  /// 주어지면 인식된 원문을 그대로 넘긴다(1~9 판정·실패 처리는 호출부의
  /// 인식 컨트롤러가 한다). 없으면 기존처럼 첫 숫자만 [onDigitEntered]로 보낸다.
  final void Function(String text)? onTextEntered;

  @override
  State<SudokuPencilInputOverlay> createState() =>
      _SudokuPencilInputOverlayState();
}

class _SudokuPencilInputOverlayState extends State<SudokuPencilInputOverlay> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant SudokuPencilInputOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectionChanged = widget.selectedRow != oldWidget.selectedRow ||
        widget.selectedCol != oldWidget.selectedCol;
    if (!selectionChanged) return;

    if (widget.selectedRow == null || widget.selectedCol == null) {
      _focusNode.unfocus();
      return;
    }

    // 셀이 바뀐 프레임에 바로 requestFocus하면 아직 새 위치로 옮겨지기 전이라
    // 포커스가 씹힐 수 있어 한 프레임 뒤로 미룬다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String text) {
    if (text.isEmpty) return;

    final onText = widget.onTextEntered;
    if (onText != null) {
      onText(text);
      _controller.clear();
      return;
    }

    final match = RegExp(r'[1-9]').firstMatch(text);
    if (match != null) {
      widget.onDigitEntered(int.parse(match.group(0)!));
    }
    // 인식된 문자를 계속 누적하지 않고 매번 비워서, 다음 필기를 위한
    // 빈 상태로 되돌린다.
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedRow == null || widget.selectedCol == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: widget.selectedCol! * widget.cellExtent,
      top: widget.selectedRow! * widget.cellExtent,
      width: widget.cellExtent,
      height: widget.cellExtent,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.none,
        showCursor: false,
        // 이 필드는 필기(Scribble) 인식 전용이다. 셀을 탭했을 때 iOS가 보여 주는
        // 선택 핸들·돋보기·'붙여넣기' 메뉴가 뜨지 않게 선택 UI를 모두 끈다.
        enableInteractiveSelection: false,
        contextMenuBuilder: (context, editableTextState) =>
            const SizedBox.shrink(),
        autocorrect: false,
        enableSuggestions: false,
        maxLines: 1,
        // 앱 테마가 모든 TextField에 둥근 테두리·배경을 주므로, 포커스·활성
        // 상태의 테두리까지 전부 꺼서 셀 위에 알약 모양이 보이지 않게 한다.
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(color: Colors.transparent),
        cursorColor: Colors.transparent,
        inputFormatters: [LengthLimitingTextInputFormatter(4)],
        onChanged: _handleChanged,
      ),
    );
  }
}
