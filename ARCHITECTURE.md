# Architecture

`sudoku159` 유지보수용 구조 설명입니다. 빠른 시작은 [`README.md`](README.md)를 보세요.

## 1. 계층 구조

| 계층 | 역할 |
|------|------|
| `view/` | Flutter 위젯·화면 조립 |
| `presenter/` | 게임 규칙, 보드, 타이머, 설정 상태 |
| `services/` | 홈·챌린지·세션·카탈로그·알림·identity |
| `database/` | SQLite + repository |

보조:

- `model/` — `SudokuLevel`, `SudokuGame` 등
- `utils/` — 퍼즐 생성, `board_codec`, 로거
- `l10n/` — ARB 생성 코드 + 레벨/업적 문자열 헬퍼 (`arb/`가 소스)

## 2. 앱 시작 흐름

진입: [`lib/main.dart`](lib/main.dart)

```
main()
  → InstallIdService.getOrCreate() (백그라운드)
  → Sudoku159App (로케일·테마·알림 prefs 로드)
  → StartupCatalogPreparingGate
       → DatabaseManager: 카탈로그 최소 준비 (레벨당 ≥1)
  → MyHomePage (하단 탭)
```

### 하단 탭 (`MyHomePage`)

| 인덱스 | 화면 | 설명 |
|--------|------|------|
| 0 | `HomeScreen` | 레벨·이어하기·오늘의 챌린지·내 페이스 |
| 1 | `RecordsStatisticsScreen` | 기록·통계 (첫 방문 시 로드) |

탭 간 이동: [`lib/navigation/root_nav_scope.dart`](lib/navigation/root_nav_scope.dart)

챌린지·업적 상세 UI: [`lib/view/challenge/`](lib/view/challenge/) (`ChallengeScreen`, `AchievementCollectionScreen`). 홈 카드에서 게임·업적 흐름으로 연결됩니다.

## 3. 데이터 저장

### SQLite (`sudoku_games.db`)

- 관리: [`lib/database/database_manager.dart`](lib/database/database_manager.dart)
- 스키마 버전: 6 (2026-05 기준)

주요 테이블:

| 테이블 | 용도 |
|--------|------|
| `games` | 퍼즐 `board` / `solution` |
| `clear_records` | 레벨·게임별 최고 기록 |
| `clear_events` | 클리어 이벤트(통계·챌린지) |
| `daily_challenge_completions` | 일일 챌린지 완료일 |
| `app_metadata` | `catalog_source` 등 (`local` / `remote`) |

최초 DB: 앱 번들 [`assets/initial_puzzles.db`](../assets/initial_puzzles.db)를 문서 디렉터리로 복사. 없거나 부족하면 생성·보충.

### SharedPreferences

| 키/서비스 | 내용 |
|-----------|------|
| `GameStateService` | 진행 보드, 메모, 타이머, 힌트, 오답, 종료 플래그 |
| `InstallIdService` | `install_id` (기기별 익명 ID) |
| `AppSettingsService` | 진동, 알림, 테마, 한손 모드 등 |

진행 세션 구현: [`lib/services/game/game_state_service.dart`](lib/services/game/game_state_service.dart)

### Identity (Firebase 없음)

- [`InstallIdService`](lib/services/identity/install_id_service.dart): 앱 최초 실행 시 UUID 형태 ID 생성·보관
- [`ClearRecordBackupPayloadService`](lib/services/records/clear_record_backup_payload_service.dart): `install_id` + 클리어 기록/이벤트 JSON 페이로드 (향후 서버 백업·DLC 연동 대비)

## 4. 퍼즐 카탈로그

### 목표 수량

- 일반 레벨: **159**문제 (`_targetGamesPerLevel`)
- 마스터: **20**문제 (`_targetMasterGames`)
- 초기 시드: 레벨당 **12**문제 (`_initialSeedGamesPerLevel`)

### 출처 (`catalog_source`)

1. **local** — `SudokuGenerator`로 생성·백그라운드 top-up
2. **remote** — [`RemotePuzzleService`](lib/services/catalog/remote_puzzle_service.dart)가 `SUDOKU_API_BASE_URL`로 카탈로그 fetch 후 SQLite 반영

`SUDOKU_API_BASE_URL` 미설정 시 remote는 비활성(`isConfigured == false`)이고 local만 사용합니다.

### 준비 상태 UI

- `DatabaseManager.catalogStatus` (`ValueNotifier<PuzzleCatalogStatus>`)
- `isReadyToPlay`: 모든 레벨에 최소 1문제
- `StartupCatalogPreparingGate`: 준비 전 로딩 게이트

### DLC·확장 포인트

`app_metadata`와 remote 카탈로그 경로는 추가 퍼즐 팩(DLC)·서버 동기화를 붙이기 위한 저장 구조입니다. 앱 스토어 IAP 등은 아직 없고, DB·메타데이터·HTTP 카탈로그만 준비된 상태입니다.

## 5. 홈 데이터 흐름

조립: [`lib/services/home/home_dashboard_service.dart`](lib/services/home/home_dashboard_service.dart)

입력:

- `GameStateService` 저장 세션
- `games` + solution
- `ChallengeProgressService`
- 업적 요약
- 통계

출력 (대표):

- `continueGame` / `continueGames`
- `todayChallenge`
- `challengeProgress`
- `achievementSummary`

최적화: 저장 게임 재조회 최소화, 보드+해답 단일 조회, 기록 탭 lazy load.

## 6. 게임 화면

화면: [`lib/view/sudoku_game/sudoku_game_screen.dart`](lib/view/sudoku_game/sudoku_game_screen.dart)

| 컴포넌트 | 책임 |
|----------|------|
| `SudokuGamePresenter` | 입력, 힌트, 메모, 완료/오답, pause |
| `SudokuBoardController` | 보드 상태, 충돌, 후보 메모, undo |
| `GameTimerController` | 경과 시간 |
| `GameSessionController` | 세션 복원·저장·삭제 |
| `GameSettingsController` | 설정 로드, wakelock |
| `GameEndFlow` | 완료/실패 다이얼로그, 공유 |
| `GameCompletionCoordinator` | 기록 저장, 업적, 챌린지, 다음 퍼즐 |

### 진입

1. 설정 로드
2. 세션 복원 여부
3. 초기 보드
4. Presenter 생성
5. 디바운스 세션 저장

### 종료

- **완료**: 기록·업적·챌린지·알림 → 완료 다이얼로그
- **실패**: 게임오버 다이얼로그

## 7. Presenter 경계

게임 규칙은 `lib/presenter/game/`에 두고, View는 상태 반영·제스처에 집중합니다.

- UI 상태 변경은 Presenter/Controller 콜백 → `setState`
- SQLite·SharedPreferences 직접 접근은 `services/`·`database/`에서만

## 8. 도메인 모델

`SudokuLevel`은 불변 정의 + `copyWith`로 진행도 반영 ([`lib/model/sudoku_level.dart`](lib/model/sudoku_level.dart)).

게임 기능 티어(힌트·메모 등): [`SudokuGameFeaturePolicy`](lib/model/sudoku_game_feature_policy.dart).

## 9. 로컬라이제이션

- 소스: [`arb/app_ko.arb`](../arb/app_ko.arb), `app_en.arb`, `app_ja.arb`
- 생성: `flutter gen-l10n` (`l10n.yaml`)
- 런타임 override: `AppLocaleScope` + `SharedPreferences` (`app_locale`)

## 10. 테스트

| 위치 | 범위 |
|------|------|
| `test/` | presenter, services, utils, 일부 widget |
| `integration_test/` | 앱 플로우 |

권장:

```bash
bash scripts/verify.sh
```

또는:

```bash
bash tool/clean_apple_double.sh
flutter analyze
flutter test
```

## 11. 유지보수 메모

### AppleDouble

macOS에서 `._*` 생성 시 analyze/test 실패 가능 → [`tool/clean_apple_double.sh`](tool/clean_apple_double.sh)

### 리팩터링 후보 (코드 기준)

- `settings_screen.dart` 설정 로직을 presenter/service로 더 분리
- 홈 대시보드 병렬 로드·캐시
- `ChallengeScreen`과 홈 챌린지 카드 UX 통합 여부 검토

### 제거된 Firebase

이전에는 Firebase Auth·`firebase_options.dart`가 있었으나 제거되었습니다. 재도입 시 `pubspec` 의존성, `flutterfire configure`, 플랫폼 설정 파일을 다시 추가해야 하며, 루트 `firebase.json`은 레거시 참고용일 뿐 현재 빌드에 쓰이지 않습니다.
