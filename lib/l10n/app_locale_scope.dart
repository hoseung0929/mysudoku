import 'package:flutter/material.dart';

/// 앱 전역 언어 변경 콜백을 자식 위젯에 전달합니다.
/// [setAppLocale]: `null`이면 시스템 언어를 따릅니다.
/// [appLocale]: [MaterialApp.locale]과 동기화해, 이 스코프에 의존하는 위젯이 갱신되도록 합니다.
class AppLocaleScope extends InheritedWidget {
  const AppLocaleScope({
    super.key,
    required this.appLocale,
    required this.setAppLocale,
    required super.child,
  });

  /// `null`이면 시스템 로케일을 따르는 상태입니다.
  final Locale? appLocale;

  final Future<void> Function(Locale? locale) setAppLocale;

  static AppLocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found above this context');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppLocaleScope oldWidget) {
    return oldWidget.appLocale != appLocale;
  }
}
