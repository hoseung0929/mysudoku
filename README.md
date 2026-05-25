# Sudoku159

Flutter로 만든 스도쿠 앱입니다. 레벨별 퍼즐 플레이, 일일 챌린지, 업적, 기록/통계, 저장 게임 복원, 알림, 프로필 설정을 지원합니다.

- 패키지명: `sudoku159`
- 앱 버전: `1.1.0+2` (`pubspec.yaml` 기준)
- 상세 구조: [`ARCHITECTURE.md`](ARCHITECTURE.md)

## 주요 기능

- 5개 난이도 레벨과 레벨별 퍼즐 카탈로그 (일반 레벨 159문제, 마스터 20문제 목표)
- 진행 중 게임 저장 및 복원
- 메모 모드, 힌트, 오답 카운트, 게임 오버
- 홈 화면의 오늘의 챌린지, 연속 플레이, 주간 목표
- 업적·기록·통계
- 결과 공유, 로컬 알림, 프로필 이미지/이름
- 한국어 / 영어 / 일본어 로컬라이제이션

## 기술 스택

| 영역 | 패키지 |
|------|--------|
| UI | Flutter, `google_fonts` |
| 로컬 DB | `sqflite` |
| 설정·세션 | `shared_preferences` |
| 원격 카탈로그 | `http` (`SUDOKU_API_BASE_URL`, 선택) |
| 기타 | `flutter_local_notifications`, `share_plus`, `image_picker`, `wakelock_plus`, `vibration` |

계정·클라우드 동기화는 **Firebase를 사용하지 않습니다**. 기기별 익명 `install_id`로 로컬 식별과 기록 백업 페이로드를 구성합니다.

## 앱 구조 (요약)

진입점: [`lib/main.dart`](lib/main.dart)

1. `StartupCatalogPreparingGate` — 퍼즐 카탈로그 준비(최소 1문제/레벨) 후 진입
2. `MyHomePage` — 하단 탭 2개
   - **홈** [`HomeScreen`](lib/view/home/home_screen.dart): 레벨 선택, 이어하기, 오늘의 챌린지, 내 페이스
   - **기록** [`RecordsStatisticsScreen`](lib/view/records/records_statistics_screen.dart): 클리어 기록·통계
3. 게임 [`SudokuGameScreen`](lib/view/sudoku_game/sudoku_game_screen.dart) — 세션/설정/종료 흐름은 전용 컨트롤러·플로우로 분리

챌린지·업적 전용 UI는 [`lib/view/challenge/`](lib/view/challenge/)에 있으며, 홈에서 오늘의 챌린지 등으로 연결됩니다.

## 디렉터리 개요

```text
lib/
  constants/     화면·통계 필터 상수
  database/      SQLite, repository
  l10n/          생성된 ARB 로컬라이제이션 + 헬퍼
  model/         SudokuLevel, SudokuGame 등
  navigation/    탭 전환 scope
  presenter/     게임·보드·타이머·설정 컨트롤러
  services/      홈, 챌린지, 세션, 카탈로그, identity 등
  theme/         라이트/다크 테마
  utils/         퍼즐 생성기, board codec, logger
  view/          화면
  view/sudoku_game/  게임 화면 전용 컨트롤러·플로우
  widgets/       공용 위젯
arb/             번역 소스 (ko, en, ja)
test/            단위·위젯 테스트
integration_test/  통합 테스트
```

## 데이터 저장

| 데이터 | 저장소 | 진입점 |
|--------|--------|--------|
| 퍼즐·클리어 기록 | SQLite (`sudoku_games.db`) | [`database_manager.dart`](lib/database/database_manager.dart) |
| 카탈로그 출처 | `app_metadata.catalog_source` (`local` / `remote`) | 동일 |
| 진행 중 세션 | SharedPreferences | [`game_state_service.dart`](lib/services/game/game_state_service.dart) |
| 설치 식별자 | SharedPreferences (`install_id`) | [`install_id_service.dart`](lib/services/identity/install_id_service.dart) |
| 홈 대시보드 | 위 소스 조합 | [`home_dashboard_service.dart`](lib/services/home/home_dashboard_service.dart) |

### 퍼즐 카탈로그

- 최초 설치: 번들 [`assets/initial_puzzles.db`](assets/initial_puzzles.db) 복사 후, 부족분은 로컬 생성 또는 원격 동기화
- `SUDOKU_API_BASE_URL`이 설정되면 HTTP 카탈로그를 SQLite에 캐시 (`remote`)
- 미설정 시 로컬 생성·보충 (`local`), 레벨당 목표는 일반 159 / 마스터 20

원격 API 실행 예:

```bash
flutter run --dart-define=SUDOKU_API_BASE_URL=https://your-api.example
```

## 게임 화면 책임 분리

| 역할 | 파일 |
|------|------|
| UI·입력 | `sudoku_game_screen.dart` |
| 규칙·타이머 | `presenter/game/sudoku_game_presenter.dart` |
| 세션 저장/복원 | `game_session_controller.dart` |
| 게임 설정 | `game_settings_controller.dart` |
| 완료/실패/공유 | `game_end_flow.dart`, `game_completion_coordinator.dart` |

## 개발 시작

```bash
flutter pub get
flutter run
```

`flutter clean` 이후나 macOS `._*` 파일로 도구가 꼬였을 때:

```bash
bash scripts/flutter_refresh_run.sh -d "iPhone 16"
```

## 검증

푸시 전 권장:

```bash
bash scripts/verify.sh
```

- AppleDouble(`._*`) 제거
- `flutter pub get` → `flutter analyze` → `flutter test`

개별 실행:

```bash
flutter test
flutter test integration_test
```

## macOS 참고

`._*` 파일이 생기면 테스트·l10n이 UTF-8 오류를 낼 수 있습니다.

```bash
bash tool/clean_apple_double.sh
```

## 레거시 파일

루트의 `firebase.json`, `.firebaserc.example`은 과거 Firebase 연동용이며 **현재 앱 빌드·런타임에 사용하지 않습니다**. Firebase Auth는 제거되었고, 관련 설정 가이드(`FIREBASE_SETUP.md`)도 삭제했습니다.

## 관련 문서

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — 계층, 시작·게임·카탈로그 흐름, 테스트
- [`skills/sudoku-design-guide/SKILL.md`](skills/sudoku-design-guide/SKILL.md) — UI 디자인 가이드 (에이전트용)
