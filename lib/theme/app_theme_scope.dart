import 'package:flutter/material.dart';

/// 앱 전역 테마 모드 변경 콜백을 자식 위젯에 전달합니다.
/// [AppLocaleScope]와 동일한 패턴.
class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    super.key,
    required this.themeMode,
    required this.setThemeMode,
    required super.child,
  });

  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode mode) setThemeMode;

  static AppThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope not found above this context');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppThemeScope oldWidget) {
    return oldWidget.themeMode != themeMode;
  }
}
