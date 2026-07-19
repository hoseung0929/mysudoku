# 태블릿(iPad) UI 작업 원칙

## 원칙

**모든 UI 수정은 아이패드/아이폰을 분기해서 작업한다.** 아이패드 대응을 위한 크기·레이아웃 변경이 아이폰 쪽 결과물에 영향을 줘서는 안 된다.

분기 방식은 화면 성격에 따라 둘 중 하나를 쓴다:

1. **명시적 `isTablet` 플래그** — 화면/카드처럼 여러 값(패딩, 폰트 크기, 아이콘 크기 등)을 한 번에 갈아끼워야 할 때. `MediaQuery` 폭(`> 600`)으로 판단한 뒤 위젯 트리 아래로 `isTablet: bool`을 넘겨서 각 값을 `isTablet ? 태블릿값 : 폰값`으로 분기한다.
2. **폭 기반 반응형 clamp** — 이미 `LayoutBuilder`/`contentWidth` 기반으로 크기를 계산하는 화면은, 그 계산식의 상한(clamp 상한값)만 올려도 된다. 아이폰은 화면 폭 자체가 기존 상한에 못 미치므로 결과가 그대로 유지되고, 아이패드처럼 폭이 넓을 때만 상한이 커진 효과가 나타난다. 이 경우 별도 `isTablet` 변수 없이도 안전하게 분기된다.

어느 방식을 쓰든, **수정 후 아이폰 시뮬레이터에서도 스크린샷으로 확인해서 기존과 동일한지 검증**한다.

## 현재 적용 현황 (2026-07-20 기준)

- **[level_picker_screen.dart](../lib/view/home/level_picker_screen.dart)** — 퍼즐 그리드 컬럼 수를 폭 기반으로 분기 (`_gridColumnsForWidth`): <600 4열(폰 동일) / 600~900 6열 / 900+ 8열.
- **[home_screen.dart](../lib/view/home/home_screen.dart)** — 명시적 `isTablet` 플래그 방식. `_buildTabletLayout()`이 `isTablet: true`를 `_buildHomeHero()` → `_buildTodaySpotlightCard()`, `_buildLevelExplorer()` → `_buildLevelCard()` → `_LevelCard`/`_DifficultyIcon`까지 전달. 레벨 리스트는 폰과 동일하게 1열 유지, 카드 자체 크기(패딩/폰트/뱃지/진행바 등)만 태블릿에서 확대.
- **[sudoku_game_screen.dart](../lib/view/sudoku_game/sudoku_game_screen.dart)** — 태블릿 전용 2분할 레이아웃(오버플로우 버그 있었음)은 제거하고 `_buildMobileLayout()` 단일 경로로 통일. 대신 `_MobileGameLayoutMetrics.fromConstraints`의 보드/키패드 크기 상한을 폭 기반으로 완화(예: 보드 460→680)해서 태블릿 폭에서만 커지도록 함. 숫자 키패드 한 줄 폭이 보드 폭과 정렬되도록 `alignedNumberButtonWidth` 계산 추가.

## 남은 화면 (아직 iPad 분기 미적용, 조사 시점 기준)

- `records_statistics_screen.dart` — 통계/차트, 하드코딩된 치수 많음
- `challenge_screen.dart` — 업적 카드 등
- `settings_screen.dart` — 설정 리스트
- `widgets/game_complete_dialog.dart` — 게임 완료 다이얼로그 (폭 제한 없어 태블릿에서 화면 끝까지 늘어남)
- `widgets/profile_editor_sheet.dart` — 프로필 편집 바텀시트
- 하단 탭바(`widgets/bottom_nav_bar.dart`, `main.dart`) — 아이패드에서 사이드 레일 전환 여부는 별도 판단 필요

## 참고

- 태블릿 대응 범위(가로 회전 지원 여부 등)는 아직 세로 전용으로 결정된 상태 (`main.dart`에서 `DeviceOrientation.portraitUp` 고정).
- iOS `TARGETED_DEVICE_FAMILY`는 앱스토어 심사 때문에 `1`(아이폰 전용)로 의도적으로 제한되어 있음. 아이패드 시뮬레이터 테스트 시에만 로컬에서 `1,2`로 임시 변경 후 작업이 끝나면 반드시 `1`로 되돌릴 것.
