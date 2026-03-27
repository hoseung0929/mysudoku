import 'package:flutter/material.dart';

/// 앱 전역 테마 모드(라이트 / 다크 / 시스템) 변경을 자식에 전달합니다.
class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    super.key,
    required this.themeMode,
    required this.setThemeMode,
    required this.highContrastEnabled,
    required this.setHighContrastEnabled,
    required this.largeTextEnabled,
    required this.setLargeTextEnabled,
    required super.child,
  });

  final ThemeMode themeMode;

  final Future<void> Function(ThemeMode mode) setThemeMode;

  final bool highContrastEnabled;

  final Future<void> Function(bool enabled) setHighContrastEnabled;

  final bool largeTextEnabled;

  final Future<void> Function(bool enabled) setLargeTextEnabled;

  static AppThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope not found above this context');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppThemeScope oldWidget) {
    return oldWidget.themeMode != themeMode ||
        oldWidget.highContrastEnabled != highContrastEnabled ||
        oldWidget.largeTextEnabled != largeTextEnabled;
  }
}
