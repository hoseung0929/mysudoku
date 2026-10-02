import 'package:flutter/material.dart';
import 'package:sudoku159/widgets/press_scale.dart';

/// 자식(버튼·카드 등)을 누르는 동안 살짝 줄인다. 자식의 탭 처리는 건드리지
/// 않고 포인터 이벤트만 듣는다. 동작 줄이기에서는 [PressScale]이 크기를
/// 바꾸지 않는다.
class PressScaleListener extends StatefulWidget {
  const PressScaleListener({super.key, required this.child});

  final Widget child;

  @override
  State<PressScaleListener> createState() => _PressScaleListenerState();
}

class _PressScaleListenerState extends State<PressScaleListener> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: PressScale(pressed: _pressed, child: widget.child),
    );
  }
}
