import 'package:flutter/material.dart';

/// 기존 난이도 마스코트 자산(투명 배경, 전신)을 화면 목적에 맞는 크기로 보여준다.
/// 장식이므로 스크린 리더에서는 제외한다. 원본 비율을 유지하고 잘라내지 않는다.
class MascotImage extends StatelessWidget {
  const MascotImage({super.key, required this.asset, required this.size});

  /// 웃으며 손을 흔드는 초급 포즈 — 시작을 반기는 자리.
  static const String welcome = 'assets/images/level1.png';

  /// 왕관과 별 메달을 든 포즈 — 성취를 축하하는 자리.
  static const String celebrate = 'assets/images/level4.png';

  final String asset;

  /// 그림이 들어가는 정사각형 박스 한 변. 이미지는 이 안에 비율대로 맞춘다.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          // 원본이 900px대라 표시 크기에 맞춰 디코딩해 메모리를 아낀다.
          cacheHeight: (size * 3).round(),
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
