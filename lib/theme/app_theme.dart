import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sudoku159/theme/app_colors.dart';

/// 앱 전체 테마. 팔레트는 [AppColors]·`skills/sudoku-design-guide`와 정렬한다.
class AppTheme {
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceTint = AppColors.surfaceSubtle;
  static const Color cardColor = AppColors.surface;

  /// 보드·셀 하이라이트용 (낮은 채도)
  static const Color mintColor = AppColors.boardAccent;
  static const Color lightBlueColor = AppColors.boardAccent2;
  static const Color yellowColor = AppColors.attentionSurface;
  static const Color pinkColor = AppColors.attention;
  static const Color hintYellowColor = AppColors.boardSurfaceTint;

  static const Color textColor = AppColors.textPrimary;
  static const Color lightTextColor = AppColors.textSecondary;
  static const Color mutedTextColor = AppColors.textMuted;
  static const Color disabledTextColor = AppColors.textDisabled;
  static const Color lineColor = AppColors.border;
  static const Color lineLightColor = AppColors.borderLight;

  /// 홈 「나만의 속도」 CTA — 스킬: 포인트는 블랙·저채도
  static const Color homeMyPaceCtaBackground = AppColors.primary;
  static const Color homeMyPaceCtaForeground = AppColors.onPrimary;

  /// 기록 통계 차트·배지 포인트 (보드 액센트와 동일 계열)
  static const Color statisticsAccent = AppColors.boardAccent;

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.surfaceSubtle,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.boardAccent,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.boardSurfaceTint,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.boardAccent2,
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: AppColors.borderLight,
      onTertiaryContainer: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderLight,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surfaceSubtle,
      surfaceContainer: AppColors.surfaceSubtle,
      surfaceContainerHigh: AppColors.borderLight,
      surfaceContainerHighest: AppColors.divider,
      error: AppColors.attention,
      onError: AppColors.onPrimary,
      errorContainer: AppColors.attentionSurface,
      onErrorContainer: AppColors.textPrimary,
    );

    const primaryTextColor = AppColors.textPrimary;
    const secondaryTextColor = AppColors.textSecondary;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: GoogleFonts.notoSansTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        displayMedium: GoogleFonts.notoSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        displaySmall: GoogleFonts.notoSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        headlineLarge: GoogleFonts.notoSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        headlineMedium: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        headlineSmall: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        titleLarge: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        titleMedium: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTextColor,
        ),
        titleSmall: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
        ),
        bodyLarge: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primaryTextColor,
        ),
        bodyMedium: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: primaryTextColor,
        ),
        bodySmall: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: secondaryTextColor,
        ),
        labelLarge: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTextColor,
        ),
        labelMedium: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
        ),
        labelSmall: GoogleFonts.notoSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: primaryTextColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryTextColor,
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(
            color: AppColors.boardAccent2,
            width: 2,
          ),
        ),
        labelStyle: GoogleFonts.notoSans(
          color: secondaryTextColor,
        ),
      ),
      extensions: const [AppColorsExtension.light],
    );
  }

  static ThemeData darkTheme() {
    const dark = AppColorsExtension.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B9FE4),
      brightness: Brightness.dark,
    ).copyWith(
      primary: dark.textPrimary,
      onPrimary: dark.background,
      primaryContainer: dark.surfaceSubtle,
      onPrimaryContainer: dark.textPrimary,
      secondary: AppColors.boardAccent,
      onSecondary: dark.textPrimary,
      secondaryContainer: const Color(0xFF2A3330),
      onSecondaryContainer: dark.textPrimary,
      tertiary: AppColors.boardAccent2,
      onTertiary: dark.textPrimary,
      tertiaryContainer: dark.borderLight,
      onTertiaryContainer: dark.textPrimary,
      surface: dark.surface,
      onSurface: dark.textPrimary,
      onSurfaceVariant: dark.textSecondary,
      outline: dark.border,
      outlineVariant: dark.borderLight,
      surfaceContainerLowest: dark.background,
      surfaceContainerLow: dark.surfaceSubtle,
      surfaceContainer: dark.surfaceSubtle,
      surfaceContainerHigh: dark.borderLight,
      surfaceContainerHighest: dark.divider,
      error: dark.attention,
      onError: dark.background,
      errorContainer: dark.attentionSurface,
      onErrorContainer: dark.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: dark.background,
      canvasColor: dark.background,
      textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.notoSans(fontSize: 32, fontWeight: FontWeight.bold, color: dark.textPrimary),
        displayMedium: GoogleFonts.notoSans(fontSize: 28, fontWeight: FontWeight.bold, color: dark.textPrimary),
        displaySmall: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: dark.textPrimary),
        headlineLarge: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.w600, color: dark.textPrimary),
        headlineMedium: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.w600, color: dark.textPrimary),
        headlineSmall: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w600, color: dark.textPrimary),
        titleLarge: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w600, color: dark.textPrimary),
        titleMedium: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500, color: dark.textPrimary),
        titleSmall: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w500, color: dark.textSecondary),
        bodyLarge: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.normal, color: dark.textPrimary),
        bodyMedium: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.normal, color: dark.textPrimary),
        bodySmall: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.normal, color: dark.textSecondary),
        labelLarge: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500, color: dark.textPrimary),
        labelMedium: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w500, color: dark.textSecondary),
        labelSmall: GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.w500, color: dark.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark.surface,
        foregroundColor: dark.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.w600, color: dark.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: dark.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: dark.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dark.textPrimary,
          foregroundColor: dark.background,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(elevation: 0, shadowColor: Colors.transparent),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark.textSecondary,
          textStyle: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark.surfaceSubtle,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: dark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: dark.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: AppColors.boardAccent2, width: 2),
        ),
        labelStyle: GoogleFonts.notoSans(color: dark.textSecondary),
      ),
      extensions: const [AppColorsExtension.dark],
    );
  }

  static TextStyle get sudokuNumberStyle {
    return GoogleFonts.notoSans(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.boardUserNumber,
    );
  }

  static TextStyle get sudokuFixedNumberStyle {
    return GoogleFonts.notoSans(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }

  static TextStyle get sudokuWrongNumberStyle {
    return GoogleFonts.notoSans(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: Colors.red.shade700,
    );
  }

  /// 숫자 패드 — 과한 그림자 지양 (스킬)
  static TextStyle get numberButtonStyle {
    return GoogleFonts.notoSans(
      fontSize: 38,
      fontWeight: FontWeight.w600,
      color: textColor,
    );
  }

  static Color get sudokuWrongNumberColor => pinkColor;

  static Color get sudokuHintNumberColor => hintYellowColor;

  static Color get sudokuSelectedNumberColor => lightBlueColor;

  static Color get sudokuSameNumberColor => mintColor;
}
