import 'package:flutter/material.dart';

Route<T> buildAppPageRoute<T>({
  required WidgetBuilder builder,
}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.08, 0.0);
      const end = Offset.zero;
      final positionTween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: Curves.easeOutCubic),
      );
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: animation.drive(positionTween),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 170),
  );
}
