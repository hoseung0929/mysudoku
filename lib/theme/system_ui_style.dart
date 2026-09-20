import 'package:flutter/services.dart';

/// 상태바·시스템 내비게이션 표시 스타일을 앱 테마 밝기에 맞춘다.
///
/// - Android는 `statusBarIconBrightness`가 "아이콘 색"(어두운 배경이면 light),
/// - iOS는 `statusBarBrightness`가 "앱 화면의 밝기"(어두운 화면이면 dark →
///   시스템이 밝은 글자를 그린다)이므로 서로 반대 방향의 값을 준다.
SystemUiOverlayStyle systemOverlayStyleFor(Brightness appBrightness) {
  final isDark = appBrightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: const Color(0x00000000),
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: const Color(0x00000000),
    systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
  );
}
