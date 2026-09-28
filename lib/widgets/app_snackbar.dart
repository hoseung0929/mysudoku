import 'package:flutter/material.dart';

/// 홈·기록·설정 탭처럼 화면 하단에 떠 있는 캡슐형 탭바가 있는 화면에서 쓰는
/// 스낵바. 기본(`SnackBarBehavior.fixed`) 스낵바는 `ScaffoldMessenger`가
/// 화면에 함께 떠 있는 여러 `Scaffold`(탭 화면 자체의 Scaffold와
/// `MyHomePage`의 바깥 Scaffold) 중 하단 탭바가 없는 안쪽 것을 기준으로
/// 여백을 계산해, 플로팅 탭바와 겹쳐 보이는 문제가 있었다. `floating` +
/// 고정 여백을 줘서 항상 탭바 위에 뜨게 한다.
void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 120),
    ),
  );
}
