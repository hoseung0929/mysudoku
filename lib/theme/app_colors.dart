import 'package:flutter/material.dart';

/// Sudoku159 제품 디자인 스킬 (`skills/sudoku-design-guide/SKILL.md`) 기준 색상.
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
  static const boardUserNumber = Color(0xFF1D4ED8);

  /// 오답·주의 (과한 원색 지양)
  static const attention = Color(0xFFC27B6B);
  static const attentionSurface = Color(0xFFF3EBE8);
}

/// 라이트/다크 모드 색상 세트. [ThemeData.extensions]에 등록해 사용한다.
/// 위젯에서는 [AppColorsContext.colors]로 접근한다.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.border,
    required this.borderLight,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.boardUserNumber,
    required this.attention,
    required this.attentionSurface,
  });

  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color border;
  final Color borderLight;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color boardUserNumber;
  final Color attention;
  final Color attentionSurface;

  static const light = AppColorsExtension(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceSubtle: AppColors.surfaceSubtle,
    border: AppColors.border,
    borderLight: AppColors.borderLight,
    divider: AppColors.divider,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    textDisabled: AppColors.textDisabled,
    boardUserNumber: AppColors.boardUserNumber,
    attention: AppColors.attention,
    attentionSurface: AppColors.attentionSurface,
  );

  static const dark = AppColorsExtension(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceSubtle: Color(0xFF242424),
    border: Color(0xFF2E2E2E),
    borderLight: Color(0xFF272727),
    divider: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFECECEC),
    textSecondary: Color(0xFF9E9E9E),
    textMuted: Color(0xFF757575),
    textDisabled: Color(0xFF4A4A4A),
    boardUserNumber: Color(0xFF6B9FE4),
    attention: Color(0xFFCF8D7E),
    attentionSurface: Color(0xFF5C2A22),
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSubtle,
    Color? border,
    Color? borderLight,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? boardUserNumber,
    Color? attention,
    Color? attentionSurface,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      boardUserNumber: boardUserNumber ?? this.boardUserNumber,
      attention: attention ?? this.attention,
      attentionSurface: attentionSurface ?? this.attentionSurface,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other == null) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      boardUserNumber: Color.lerp(boardUserNumber, other.boardUserNumber, t)!,
      attention: Color.lerp(attention, other.attention, t)!,
      attentionSurface: Color.lerp(attentionSurface, other.attentionSurface, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
