# Architecture

이 문서는 `mysudoku`의 현재 구조를 유지보수 관점에서 설명합니다. 빠른 시작은 `README.md`, 모듈 책임과 데이터 흐름은 이 문서를 기준으로 보면 됩니다.

## 1. 앱 전체 구조

앱은 크게 4개 층으로 나뉩니다.

- `view`
  - Flutter 위젯과 화면 조립
- `presenter`
  - 게임 플레이 로직과 보드 조작
- `services`
  - 화면용 데이터 집계, 세션 저장, 업적/챌린지/설정 처리
- `database`
  - SQLite 저장소와 repository 계층

보조 계층은 아래 역할을 가집니다.

- `model`
  - `SudokuLevel`, `SudokuGame` 같은 도메인 모델
- `utils`
  - 퍼즐 생성기, 보드 직렬화, 로거
- `l10n`
  - 다국어 문자열과 레벨 이름/업적 문자열 헬퍼

## 2. 앱 시작 흐름

진입점은 [`lib/main.dart`](lib/main.dart)입니다.

### 시작 순서

1. `main()`에서 Flutter 바인딩을 초기화합니다.
2. `MySudokuApp`이 로케일, 테마, 알림 설정을 불러옵니다.
3. `MyHomePage`가 탭 구조를 띄우고 레벨 진행도를 초기화합니다.

### 홈 탭 구조

- `LevelSelectionMain`
  - 홈/레벨 선택 허브
- `ChallengeScreen`
  - 오늘의 챌린지, 주간 목표, 업적
- `RecordsStatisticsScreen`
  - 기록, 추세, 레벨별 통계

탭 이동은 [`lib/navigation/root_nav_scope.dart`](lib/navigation/root_nav_scope.dart)로 화면 간 느슨하게 연결합니다.

## 3. 데이터 저장 전략

앱은 저장 책임을 둘로 나눕니다.

### SQLite

퍼즐 원본과 클리어 기록은 SQLite에 저장합니다.

- 구현 진입점: [`lib/database/database_manager.dart`](lib/database/database_manager.dart)
- 주요 테이블
  - `games`
  - `clear_records`

### SharedPreferences

진행 중 게임 세션은 `SharedPreferences`에 저장합니다.

- 구현 진입점: [`lib/services/game_state_service.dart`](lib/services/game_state_service.dart)
- 저장 내용
  - 현재 보드
  - 메모 후보 숫자
  - 경과 시간
  - 힌트 잔여 수
  - 오답 수
  - 메모 모드 여부
  - 힌트가 채운 셀
  - 완료/게임오버 여부

이 분리 덕분에 퍼즐 원본/기록은 영속 저장소에, “현재 플레이 중인 임시 상태”는 가벼운 저장소에 둘 수 있습니다.

## 4. 퍼즐 카탈로그 흐름

퍼즐 카탈로그는 앱 내부에서 생성하고 보충합니다.

- 구현 진입점: [`lib/database/database_manager.dart`](lib/database/database_manager.dart)

### 동작 방식

1. DB가 비어 있으면 레벨별 초기 시드 퍼즐을 생성합니다.
2. 앱이 열릴 때 부족한 퍼즐 수를 백그라운드에서 채웁니다.
3. 목표 수량은 현재 레벨별 100개입니다.

퍼즐 원본과 해답은 `games` 테이블에 함께 저장됩니다. 최근 리팩터링 이후 홈 대시보드는 `board`와 `solution`을 한 번의 조회로 읽습니다.

## 5. 홈 화면 데이터 흐름

홈 데이터는 [`lib/services/home_dashboard_service.dart`](lib/services/home_dashboard_service.dart)가 조립합니다.

### 입력 소스

- 저장 게임 세션
- 퍼즐 원본/해답 엔트리
- 챌린지 진행도
- 업적 요약
- 전체 평균 기록

### 출력 모델

- `continueGame`
  - 가장 최근 이어하기 대상
- `continueGames`
  - 저장 게임 목록
- `todayChallenge`
  - 오늘의 챌린지 퍼즐
- `challengeProgress`
  - 스트릭/주간 목표 요약
- `achievementSummary`
  - 업적 상태

### 최근 최적화 포인트

- 저장 세션을 재조회하지 않고 `getSavedGames()` 결과의 세션을 재사용
- 퍼즐 원본과 해답을 한 번의 조회로 로드
- 홈 첫 화면은 최근 저장 게임 일부만 우선 로드
- 전체 저장 게임 목록은 Saved Games 화면 진입 시 별도 로드

## 6. 게임 화면 구조

실제 게임 화면은 [`lib/view/sudoku_game_screen.dart`](lib/view/sudoku_game_screen.dart)입니다.

예전에는 이 파일에 세션 복원, 설정 로드, 종료 다이얼로그, 저장 처리까지 많이 모여 있었고, 최근 리팩터링으로 책임을 나눴습니다.

### 현재 역할 분리

- `SudokuGameScreen`
  - UI 조립
  - Presenter 연결
  - 화면 상태 갱신
- [`lib/presenter/sudoku_game_presenter.dart`](lib/presenter/sudoku_game_presenter.dart)
  - 게임 규칙, 타이머, 입력 처리
- [`lib/view/sudoku_game/game_session_controller.dart`](lib/view/sudoku_game/game_session_controller.dart)
  - 세션 복원/저장/삭제
- [`lib/view/sudoku_game/game_settings_controller.dart`](lib/view/sudoku_game/game_settings_controller.dart)
  - 게임 설정 로드와 wakelock 적용
- [`lib/view/sudoku_game/game_end_flow.dart`](lib/view/sudoku_game/game_end_flow.dart)
  - 완료/실패/공유 다이얼로그 흐름
- [`lib/view/sudoku_game/game_completion_coordinator.dart`](lib/view/sudoku_game/game_completion_coordinator.dart)
  - 기록 저장, 업적 변화, 챌린지 후처리, 다음 퍼즐 계산

### 게임 진입 흐름

1. 설정 로드
2. 세션 복원 가능 여부 판단
3. 초기 보드 결정
4. Presenter 생성
5. 플레이 중 상태 변화에 맞춰 UI 반영
6. 세션은 디바운스 저장

### 게임 종료 흐름

- 완료 시
  - 기록 저장
  - 업적 변화 확인
  - 챌린지/알림 후처리
  - 완료 다이얼로그 표시
- 실패 시
  - 게임오버 다이얼로그 표시

## 7. Presenter / Controller 경계

게임 플레이 핵심 로직은 `presenter` 아래에 있습니다.

- [`lib/presenter/sudoku_game_presenter.dart`](lib/presenter/sudoku_game_presenter.dart)
  - 입력 처리, 힌트, 메모, 완료/오답 판정
- [`lib/presenter/sudoku_board_controller.dart`](lib/presenter/sudoku_board_controller.dart)
  - 보드 상태, 선택 셀, 충돌 판정, 메모 관리
- [`lib/presenter/game_timer_controller.dart`](lib/presenter/game_timer_controller.dart)
  - 타이머 전용 책임

이 구조는 “UI는 View, 규칙과 상태 전환은 Presenter/Controller”로 나누려는 방향입니다.

## 8. 도메인 모델 원칙

현재 `SudokuLevel`은 불변 모델입니다.

- 구현: [`lib/model/sudoku_level.dart`](lib/model/sudoku_level.dart)

레벨 정의 자체는 정적 불변 데이터로 두고, 진행도는 `copyWith`로 만든 새 모델을 화면 상태가 들고 갑니다. 전역 가변 리스트를 직접 수정하던 구조보다 추적이 쉬워지고 화면 간 결합이 줄었습니다.

## 9. 테스트 전략

테스트는 `test/`와 `integration_test/`에 있습니다.

현재는 아래 영역에 테스트가 잘 붙어 있습니다.

- Presenter 로직
- 서비스 계층
- 퍼즐 생성기
- 일부 위젯 및 게임 효과

### 권장 검증 순서

```bash
bash tool/clean_apple_double.sh
flutter analyze
flutter test
```

또는 아래 스크립트를 사용합니다.

```bash
bash scripts/verify.sh
```

## 10. 유지보수 메모

### AppleDouble 파일

macOS 환경에서는 `._*` 파일이 생겨서 테스트/로컬라이제이션 도구가 UTF-8 오류를 낼 수 있습니다.

- 정리 스크립트: [`tool/clean_apple_double.sh`](tool/clean_apple_double.sh)

### 다음 리팩터링 후보

- `settings_screen.dart`도 `SudokuGameScreen`처럼 설정 처리 책임 분리
- 홈 대시보드 서비스의 병렬화 또는 캐시 전략 보강
- `ARCHITECTURE.md`에 시퀀스 다이어그램 수준의 흐름 추가
