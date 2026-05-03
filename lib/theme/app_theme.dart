import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 전체에서 사용할 테마 클래스
class AppTheme {
  // 색상 정의
  static const Color backgroundColor = Color(0xFFF7F6F0);
  static const Color surfaceTint = Color(0xFFF1F0E8);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color mintColor = Color(0xFF9DB59D);
  static const Color lightBlueColor = Color(0xFF7F9B82);
  static const Color yellowColor = Color(0xFFF1E5CD);
  static const Color pinkColor = Color(0xFFF4A261);
  static const Color hintYellowColor = Color(0xFFDCE8DD);
  static const Color textColor = Color(0xFF263A2E);
  static const Color lightTextColor = Color(0xFF7B857D);
  static const Color lineColor = Color(0xFFE3E1D8);

  /// 홈 히어로 「나만의 속도」 주요 CTA.
  static const Color homeMyPaceCtaBackground = Color(0xFF7F9B82);
  static const Color homeMyPaceCtaForeground = textColor;

  /// 라이트 테마
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: mintColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: mintColor,
      onPrimary: textColor,
      secondary: lightBlueColor,
      tertiary: pinkColor,
      surface: cardColor,
      surfaceContainerLowest: backgroundColor,
      surfaceContainerLow: const Color(0xFFF5F4ED),
      surfaceContainer: surfaceTint,
      surfaceContainerHigh: const Color(0xFFEFEEE6),
      surfaceContainerHighest: const Color(0xFFE8E6DC),
      outline: lineColor,
      outlineVariant: lineColor,
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
