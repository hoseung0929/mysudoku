import 'package:flutter/material.dart';

/// 레벨 선택 화면(퍼즐 목록)의 완료/진행 중/새 퍼즐 상태 색상.
/// 라이트/다크 모드 값을 모두 가지며, [LevelStatusPalette.of]로 현재 테마에 맞는
/// 세트를 가져온다.
class LevelStatusPalette {
  const LevelStatusPalette({
    required this.primaryPurple,
    required this.completedBackground,
    required this.completedBorder,
    required this.completedNumberText,
    required this.inProgressPrimary,
    required this.inProgressBackground,
    required this.inProgressBorder,
    required this.screenBackground,
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.disabledText,
    required this.defaultBorder,
    required this.progressTrack,
    required this.filterSelectedBackground,
    required this.filterSelectedBorder,
    required this.filterUnselectedText,
  });

  final Color primaryPurple;
  final Color completedBackground;
  final Color completedBorder;
  final Color completedNumberText;

  final Color inProgressPrimary;
  final Color inProgressBackground;
  final Color inProgressBorder;

  final Color screenBackground;
  final Color cardBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color disabledText;
  final Color defaultBorder;
  final Color progressTrack;

  final Color filterSelectedBackground;
  final Color filterSelectedBorder;
  final Color filterUnselectedText;

  static const light = LevelStatusPalette(
    primaryPurple: Color(0xFF4A3F99),
    completedBackground: Color(0xFFF5F3FF),
    completedBorder: Color(0xFFD8D2F5),
    completedNumberText: Color(0xFF606060),
    inProgressPrimary: Color(0xFF2E78B7),
    inProgressBackground: Color(0xFFEAF3F9),
    inProgressBorder: Color(0xFF8DB4D1),
    screenBackground: Color(0xFFF6F6F4),
    cardBackground: Color(0xFFFFFFFF),
    primaryText: Color(0xFF222222),
    secondaryText: Color(0xFF707070),
    tertiaryText: Color(0xFF8A8A8A),
    disabledText: Color(0xFFBDBDBD),
    defaultBorder: Color(0xFFDEDEDE),
    progressTrack: Color(0xFFE7E7E5),
    filterSelectedBackground: Color(0xFFF0EDFF),
    filterSelectedBorder: Color(0xFF8D83C9),
    filterUnselectedText: Color(0xFF666666),
  );

  static const dark = LevelStatusPalette(
    primaryPurple: Color(0xFF9C90E8),
    completedBackground: Color(0xFF2A2645),
    completedBorder: Color(0xFF433C6E),
    completedNumberText: Color(0xFFA9A4C4),
    inProgressPrimary: Color(0xFF5AB4ED),
    inProgressBackground: Color(0xFF15303F),
    inProgressBorder: Color(0xFF428ABB),
    screenBackground: Color(0xFF121212),
    cardBackground: Color(0xFF1E1E1E),
    primaryText: Color(0xFFECECEC),
    secondaryText: Color(0xFF9E9E9E),
    tertiaryText: Color(0xFF7A7A7A),
    disabledText: Color(0xFF5A5A5A),
    defaultBorder: Color(0xFF333333),
    progressTrack: Color(0xFF2E2E2E),
    filterSelectedBackground: Color(0xFF2E2A4A),
    filterSelectedBorder: Color(0xFF6E63A8),
    filterUnselectedText: Color(0xFFB0B0B0),
  );

  static LevelStatusPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

/// 테마와 무관한 크기/투명도 상수.
abstract final class LevelStatusColors {
  static const inProgressBorderWidth = 1.5;
  static const completedCheckIconSize = 12.6; // 기존 14 대비 10% 축소
  static const completedCheckIconOpacity = 0.85;
}
