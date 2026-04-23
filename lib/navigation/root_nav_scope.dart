import 'package:flutter/material.dart';

/// [MyHomePage]이 제공하는 하단 탭 전환. 홈·기록 화면에서 다른 탭으로 이동할 때 사용합니다.
class RootNavScope extends InheritedWidget {
  const RootNavScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  final ValueChanged<int> goToTab;

  static RootNavScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<RootNavScope>();
  }

  static RootNavScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'RootNavScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant RootNavScope oldWidget) {
    return !identical(goToTab, oldWidget.goToTab);
  }
}
