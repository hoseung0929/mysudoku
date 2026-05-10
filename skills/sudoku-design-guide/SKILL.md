---
name: sudoku-design-guide
description: Apply the Sudoku159 product design guide when editing or creating UI in this project. Use this skill for screen redesigns, visual polish, layout cleanup, naming/label refinement, and feature UI work that should match the app's calm Sudoku-focused style instead of generic wellness or AI-generated dashboard aesthetics.
---

# Sudoku Design Guide

Use this skill when changing UI for `sudoku159` so new work matches the app's established product direction.

## Purpose

이 Skill은 Flutter 화면을 **밝은 오프화이트 배경, 흰색 카드, 얇은 보더, 차분한 포인트 컬러, 정돈된 여백**을 가진 `Sudoku159`의 제품 톤에 맞춰 구현하기 위한 디자인 기준이다.

전체 UI는 화려한 장식보다 **정렬, 여백, 계층 구조, 카드 구분감**을 중심으로 완성한다. 화면은 웰니스 앱처럼 감성적으로 흐르거나, 범용 SaaS 대시보드처럼 건조하게 보이지 않도록 하고, **스도쿠 기록과 플레이 흐름이 중심인 제품 화면**처럼 느껴지게 만든다.

---

## Design Keywords

- Minimal
- Clean
- Sudoku-focused
- Records-first
- Soft contrast
- Thin border
- Rounded cards
- Warm light theme
- Calm product UI
- Structured and readable layout
---

## Core Visual Direction

화면은 다음 스타일을 기준으로 구현한다.

- 전체 배경은 완전한 흰색이 아니라 아주 연한 회색을 사용한다.
- 주요 콘텐츠 영역은 흰색 카드로 구분한다.
- 그림자는 거의 사용하지 않고, 얇은 보더로 영역을 구분한다.
- 포인트 컬러는 원색이 아니라 블랙 또는 낮은 채도의 색을 사용한다.
- 버튼, 카드, 입력창, 테이블의 높이와 여백을 일관되게 유지한다.
- 화면이 “AI가 만든 화려한 디자인”처럼 보이지 않도록 과한 그라데이션, 강한 그림자, 원색 사용을 피한다.


---

## Color System

### Background Colors

Use these colors as default.

```dart
class AppColors {
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

  static const primary = Color(0xFF1F1F1F);
  static const primaryText = Color(0xFFFFFFFF);
}
```

## 코드 매핑

앱에 반영된 팔레트·테마: `lib/theme/app_colors.dart`, `lib/theme/app_theme.dart`  
(보드 전용 톤은 `AppColors.boardAccent` 등으로 `primary`와 구분)
