# 태블릿(iPad) UI 작업 원칙

## 원칙

**모든 UI 수정은 아이패드/아이폰을 분기해서 작업한다.** 아이패드 대응을 위한 크기·레이아웃 변경이 아이폰 쪽 결과물에 영향을 줘서는 안 된다.

분기 방식은 화면 성격에 따라 둘 중 하나를 쓴다:

1. **명시적 `isTablet` 플래그** — 화면/카드처럼 여러 값(패딩, 폰트 크기, 아이콘 크기 등)을 한 번에 갈아끼워야 할 때. `MediaQuery` 폭(`> 600`)으로 판단한 뒤 위젯 트리 아래로 `isTablet: bool`을 넘겨서 각 값을 `isTablet ? 태블릿값 : 폰값`으로 분기한다.
2. **폭 기반 반응형 clamp** — 이미 `LayoutBuilder`/`contentWidth` 기반으로 크기를 계산하는 화면은, 그 계산식의 상한(clamp 상한값)만 올려도 된다. 아이폰은 화면 폭 자체가 기존 상한에 못 미치므로 결과가 그대로 유지되고, 아이패드처럼 폭이 넓을 때만 상한이 커진 효과가 나타난다. 이 경우 별도 `isTablet` 변수 없이도 안전하게 분기된다.

어느 방식을 쓰든, **수정 후 아이폰 시뮬레이터에서도 스크린샷으로 확인해서 기존과 동일한지 검증**한다.

## 현재 적용 현황 (2026-07-25 기준)

- **[level_picker_screen.dart](../lib/view/home/level_picker_screen.dart)** — 퍼즐 그리드 컬럼 수를 폭 기반으로 분기 (`_gridColumnsForWidth`): <600 4열(폰 동일) / 600~900 6열 / 900+ 8열.
- **[home_screen.dart](../lib/view/home/home_screen.dart)** — 명시적 `isTablet` 플래그 방식. `_buildTabletLayout()`이 `isTablet: true`를 `_buildHomeHero()` → `_buildTodaySpotlightCard()`, `_buildLevelExplorer()` → `_buildLevelCard()` → `_LevelCard`/`_DifficultyIcon`까지 전달. 레벨 리스트는 폰과 동일하게 1열 유지, 카드 자체 크기(패딩/폰트/뱃지/진행바 등)만 태블릿에서 확대.
- **[sudoku_game_screen.dart](../lib/view/sudoku_game/sudoku_game_screen.dart)** — 태블릿 전용 2분할 레이아웃(오버플로우 버그 있었음)은 제거하고 `_buildMobileLayout()` 단일 경로로 통일. 대신 `_MobileGameLayoutMetrics.fromConstraints`의 보드/키패드 크기 상한을 폭 기반으로 완화(예: 보드 460→680)해서 태블릿 폭에서만 커지도록 함. 숫자 키패드 한 줄 폭이 보드 폭과 정렬되도록 `alignedNumberButtonWidth` 계산 추가.
- **[records_statistics_screen.dart](../lib/view/records/records_statistics_screen.dart)** — `isTablet` 플래그로 통계/차트 치수 분기.
- **[challenge_screen.dart](../lib/view/challenge/challenge_screen.dart)** — `isTablet` 플래그로 업적 카드 등 분기.
- **[settings_screen.dart](../lib/view/settings/settings_screen.dart)** — `isTablet` 플래그로 설정 리스트 분기.
- **[widgets/game_complete_dialog.dart](../lib/widgets/game_complete_dialog.dart)** — `isTablet`일 때 `dialogMaxWidth = 440.0`으로 캡 (이전엔 태블릿에서 화면 끝까지 늘어나던 문제 해결).
- **[widgets/bottom_nav_bar.dart](../lib/widgets/bottom_nav_bar.dart)** — `isTablet` 플래그로 하단 탭바 치수 분기 (사이드 레일 전환은 아님, 폭만 확대).
- **[view/home/force_update_gate.dart](../lib/view/home/force_update_gate.dart)** — `startup_catalog_preparing_gate.dart`와 동일하게 `ConstrainedBox(maxWidth: 420)`로 센터 정렬 (별도 `isTablet` 분기 없이도 안전).

## 남은 화면 (아직 iPad 분기 미적용)

- `widgets/profile_editor_sheet.dart` — 프로필 편집 바텀시트
- 하단 탭바를 사이드 레일로 전환할지 여부 — `bottom_nav_bar.dart`는 치수만 확대했을 뿐 레이아웃 자체(사이드 레일 등)를 바꾸지는 않음. 별도 판단 필요.

## 참고

- 태블릿 대응 범위는 현재 세로 전용으로 되어 있음 (`main.dart`에서 `DeviceOrientation.portraitUp` 고정, `Info.plist`의 `UISupportedInterfaceOrientations~ipad`도 세로만 선언, 2026-07-25). **아이패드 정식 배포 전에 가로 모드 지원이 필수로 추가되어야 함 (2026-07-26 결정) — 그때 이 세로 고정과 Info.plist 설정을 함께 되돌려야 함.**
- `Info.plist`에 `UIRequiresFullScreen = true`를 추가해 아이패드 Slide Over/Split View 멀티태스킹을 비활성화함 (2026-07-25) — 좁은 창 폭 레이아웃을 검증하지 않은 상태에서 대응 범위를 좁히기 위한 결정. 추후 멀티태스킹 지원을 결정하면 이 값을 제거하고 좁은 폭에서의 레이아웃을 검증해야 함.
- iOS `TARGETED_DEVICE_FAMILY`는 다시 `1`(아이폰 전용)로 되돌려져 있음 (2026-07-26). **아이패드 앱스토어 정식 배포는 (1) 애플펜슬 필기 입력, (2) 가로 모드 지원이 모두 구현된 이후로 보류됨.** 아이패드 시뮬레이터로 태블릿 UI를 확인할 때만 로컬에서 `1,2`로 임시 변경하고, 확인이 끝나면 반드시 `1`로 되돌릴 것.
