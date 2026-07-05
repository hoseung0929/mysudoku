import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 제자리에서 뒤뚱거리는(bob+tilt) 펭귄 아이콘.
/// [active]가 false면 정지 상태를 유지하고, true가 되면 뒤뚱거리기 시작합니다.
class WaddlingPenguinIcon extends StatefulWidget {
  const WaddlingPenguinIcon({super.key, this.size = 22, this.active = true});

  final double size;
  final bool active;

  @override
  State<WaddlingPenguinIcon> createState() => _WaddlingPenguinIconState();
}

class _WaddlingPenguinIconState extends State<WaddlingPenguinIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waddleController;

  @override
  void initState() {
    super.initState();
    _waddleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.active) {
      _waddleController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaddlingPenguinIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _waddleController.repeat();
    } else if (!widget.active && oldWidget.active) {
      _waddleController.animateTo(0, duration: const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    _waddleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waddleController,
      builder: (context, child) {
        // t=0 (정지 상태 포함)에서 항상 정자세(bob=0, tilt=0)가 되도록
        // 사인 곡선 기준으로 계산합니다.
        final t = _waddleController.value;
        final phase = t * 2 * math.pi;
        final tilt = math.sin(phase) * 0.14;
        final bob = -3.0 * math.sin(phase).abs();
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(angle: tilt, child: child),
        );
      },
      child: Image.asset(
        'assets/images/character.png',
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
