import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final int? selectedRow;
  final int? selectedCol;
  final double cellExtent;
  final void Function(int digit) onDigitEntered;

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
        maxLines: 1,
        decoration: const InputDecoration(
          border: InputBorder.none,
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
