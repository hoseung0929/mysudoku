import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 전체에서 사용할 테마 클래스
class AppTheme {
  // 색상 정의
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color mintColor = Color(0xFFB8E6B8);
  static const Color lightBlueColor = Color(0xFFB8D4E6);
  static const Color yellowColor = Color(0xFFF4E4A6);
  static const Color pinkColor = Color(0xFFE6B8C8);
  static const Color hintYellowColor = Color(0xFFFFF2CC);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF34495E);

  /// 라이트 테마
  static ThemeData lightTheme({bool highContrast = false}) {
    final base = ColorScheme.fromSeed(
      seedColor: mintColor,
      brightness: Brightness.light,
    );
    final colorScheme = highContrast
        ? base.copyWith(
            primary: const Color(0xFF005A36),
            onPrimary: Colors.white,
            secondary: const Color(0xFF004D73),
            tertiary: const Color(0xFF8A4B00),
            surface: Colors.white,
            surfaceContainerLow: const Color(0xFFF7F9FB),
            surfaceContainerHigh: Colors.white,
            surfaceContainerHighest: const Color(0xFFF0F4F7),
            onSurface: const Color(0xFF101418),
            onSurfaceVariant: const Color(0xFF27313A),
            outline: const Color(0xFF3B4A57),
          )
        : base;
    final primaryTextColor =
        highContrast ? colorScheme.onSurface : textColor;
    final secondaryTextColor =
        highContrast ? colorScheme.onSurfaceVariant : lightTextColor;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          highContrast ? colorScheme.surface : backgroundColor,
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
        backgroundColor: highContrast ? colorScheme.surface : cardColor,
        foregroundColor: primaryTextColor,
        elevation: 2,
        shadowColor:
            highContrast ? colorScheme.outline.withValues(alpha: 0.3) : Colors.black12,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
      ),
      // 카드 테마
      cardTheme: CardThemeData(
        color: highContrast ? colorScheme.surface : cardColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast
              ? BorderSide(color: colorScheme.outline, width: 1.2)
              : BorderSide.none,
        ),
      ),
      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              highContrast ? colorScheme.primary : mintColor,
          foregroundColor:
              highContrast ? colorScheme.onPrimary : textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
        fillColor:
            highContrast ? colorScheme.surfaceContainerHighest : backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: highContrast ? colorScheme.outline : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: highContrast ? colorScheme.outline : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: highContrast ? colorScheme.primary : mintColor,
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
  static ThemeData darkTheme({bool highContrast = false}) {
    final base = ColorScheme.fromSeed(
      seedColor: mintColor,
      brightness: Brightness.dark,
    );
    final colorScheme = highContrast
        ? base.copyWith(
            primary: const Color(0xFF7EF0B0),
            onPrimary: const Color(0xFF082014),
            secondary: const Color(0xFF8ED8FF),
            tertiary: const Color(0xFFFFD58A),
            surface: const Color(0xFF0F141A),
            surfaceContainerLow: const Color(0xFF141A21),
            surfaceContainerHigh: const Color(0xFF1A2028),
            surfaceContainerHighest: const Color(0xFF222A34),
            onSurface: Colors.white,
            onSurfaceVariant: const Color(0xFFE5E7EB),
            outline: const Color(0xFFB6C0CC),
          )
        : base;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: highContrast
          ? colorScheme.surface
          : colorScheme.surfaceContainerLowest,
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
          borderRadius: BorderRadius.circular(12),
          side: highContrast
              ? BorderSide(color: colorScheme.outline, width: 1.2)
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: highContrast
              ? colorScheme.primary
              : mintColor.withValues(alpha: 0.85),
          foregroundColor: highContrast
              ? colorScheme.onPrimary
              : const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
