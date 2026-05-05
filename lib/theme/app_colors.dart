import 'package:flutter/material.dart';

/// MySudoku 제품 디자인 스킬 (`skills/sudoku-design-guide/SKILL.md`) 기준 색상.
/// 밝은 오프화이트 배경, 흰 카드, 얇은 보더, 낮은 채도·부드러운 대비.
abstract final class AppColors {
  static const background = Color(0xFFF4F4F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFFAFAF9);

  static const border = Color(0xFFE5E5E3);
  static const borderLight = Color(0xFFEEEEEC);
  static const divider = Color(0xFFE8E8E6);

  static const textPrimary = Color(0xFF1F1F1F);
  static const textSecondary = Color(0xFF6F6F6F);
  static const textMuted = Color(0xFF9A9A9A);
  static const textDisabled = Color(0xFFBDBDBD);

  /// 주요 액션·강조 (원색 대신 거의 블랙)
  static const primary = Color(0xFF1F1F1F);
  static const onPrimary = Color(0xFFFFFFFF);

  /// 스도쿠 보드·히트맵 등 **플레이 구역**만 구분용 낮은 채도 톤
  static const boardAccent = Color(0xFF8A9A8C);
  static const boardAccent2 = Color(0xFF7A8B84);
  static const boardSurfaceTint = Color(0xFFE8EDEA);

  /// 오답·주의 (과한 원색 지양)
  static const attention = Color(0xFFC27B6B);
  static const attentionSurface = Color(0xFFF3EBE8);
}
