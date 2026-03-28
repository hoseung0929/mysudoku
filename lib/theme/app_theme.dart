import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 전체에서 사용할 테마 클래스
class AppTheme {
  // 색상 정의
  static const Color backgroundColor = Color(0xFFFDFBF6);
  static const Color surfaceTint = Color(0xFFF8F4E8);
  static const Color cardColor = Color(0xFFFFFDF9);
  static const Color mintColor = Color(0xFF285B3F);
  static const Color lightBlueColor = Color(0xFF457B9D);
  static const Color yellowColor = Color(0xFFF1E5CD);
  static const Color pinkColor = Color(0xFFF4A261);
  static const Color hintYellowColor = Color(0xFFE8F1F8);
  static const Color textColor = Color(0xFF21382A);
  static const Color lightTextColor = Color(0xFF66776C);
  static const Color lineColor = Color(0xFFE4DED3);

  /// 라이트 테마
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: mintColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: mintColor,
      onPrimary: const Color(0xFFFDFBF6),
      secondary: lightBlueColor,
      tertiary: pinkColor,
      surface: cardColor,
      surfaceContainerLowest: backgroundColor,
      surfaceContainerLow: const Color(0xFFF9F6EF),
      surfaceContainer: surfaceTint,
      surfaceContainerHigh: const Color(0xFFF4EFE5),
      surfaceContainerHighest: const Color(0xFFEFE8DC),
      outline: lineColor,
      outlineVariant: const Color(0xFFE9E3D8),
      onSurface: textColor,
      onSurfaceVariant: lightTextColor,
    );
    const primaryTextColor = textColor;
    const secondaryTextColor = lightTextColor;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      textTheme: GoogleFonts.notoSansTextTheme().copyWith(
        // 제목 스타일
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
        // 헤드라인 스타일
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
        // 제목 스타일
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
        // 본문 스타일
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
        // 라벨 스타일
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
      // 앱바 테마
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
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
      // 카드 테마
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: lineColor),
        ),
      ),
      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mintColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // 텍스트 버튼 테마
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryTextColor,
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(
            color: lineColor,
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(
            color: lineColor,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(
            color: lightBlueColor,
            width: 2,
          ),
        ),
        labelStyle: GoogleFonts.notoSans(
          color: secondaryTextColor,
        ),
      ),
    );
  }

  /// 다크 테마
  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: mintColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF88B79C),
      onPrimary: const Color(0xFF102117),
      secondary: const Color(0xFF86AFC5),
      tertiary: const Color(0xFFE0A070),
      outline: const Color(0xFF38453D),
      outlineVariant: const Color(0xFF2D372F),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerHigh,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mintColor.withValues(alpha: 0.85),
          foregroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 스도쿠 숫자용 폰트 스타일
  static TextStyle get sudokuNumberStyle {
    return GoogleFonts.notoSans(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: textColor,
    );
  }

  /// 스도쿠 고정 숫자용 폰트 스타일
  static TextStyle get sudokuFixedNumberStyle {
    return GoogleFonts.notoSans(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }

  /// 스도쿠 오답 숫자용 폰트 스타일
  static TextStyle get sudokuWrongNumberStyle {
    return GoogleFonts.notoSans(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: Colors.red.shade700,
    );
  }

  /// 숫자 버튼용 폰트 스타일
  static TextStyle get numberButtonStyle {
    return GoogleFonts.notoSans(
      fontSize: 38,
      fontWeight: FontWeight.w600,
      color: textColor,
      shadows: const [
        Shadow(
          color: Colors.black12,
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    );
  }

  /// 스도쿠 오답 숫자 배경색
  static Color get sudokuWrongNumberColor => pinkColor;

  /// 스도쿠 힌트 숫자 배경색
  static Color get sudokuHintNumberColor => hintYellowColor;

  /// 스도쿠 선택된 숫자 배경색
  static Color get sudokuSelectedNumberColor => lightBlueColor;

  /// 스도쿠 같은 숫자 배경색
  static Color get sudokuSameNumberColor => mintColor;
}
