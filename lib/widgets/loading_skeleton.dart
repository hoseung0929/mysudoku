import 'package:flutter/material.dart';

/// 로딩 자리 표시자의 색을 한 번에 은은하게 변화시킨다. 동작 줄이기 설정에서는
/// 애니메이션을 멈추고 중간 밝기로 고정한다.
class LoadingSkeletonPulse extends StatefulWidget {
  const LoadingSkeletonPulse({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, Color color) builder;

  @override
  State<LoadingSkeletonPulse> createState() => _LoadingSkeletonPulseState();
}

class _LoadingSkeletonPulseState extends State<LoadingSkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 0.5,
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final color = Color.lerp(
            colorScheme.surfaceContainerHighest,
            colorScheme.onSurface.withValues(alpha: 0.12),
            _controller.value,
          )!;
          return widget.builder(context, color);
        },
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.color,
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  final Color color;
  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
