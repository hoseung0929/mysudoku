# MySudoku

Flutter로 만든 스도쿠 앱입니다. 단순 퍼즐 플레이를 넘어서 일일 챌린지, 업적, 통계, 저장 게임 복원, 알림, 프로필 커스터마이징까지 포함하는 구조로 개발되어 있습니다.

## 주요 기능

- 5개 난이도 레벨과 레벨별 퍼즐 카탈로그
- 진행 중 게임 저장 및 복원
- 메모 모드, 힌트, 오답 카운트, 게임 오버
- 일일 챌린지, 연속 플레이, 주간 목표
- 업적 배지와 기록/통계 화면
- 공유, 로컬 알림, 프로필 이미지/이름 설정
- 한국어/영어 로컬라이제이션

## 기술 스택

- Flutter
- Dart
- `sqflite`
- `shared_preferences`
- `flutter_local_notifications`
- `share_plus`
- `image_picker`
- `wakelock_plus`
- `vibration`

## 앱 구조

앱 진입점은 [`lib/main.dart`](lib/main.dart)입니다.

- 홈 탭 구성
  - `LevelSelectionMain`: 홈/레벨 선택 허브
  - `ChallengeScreen`: 일일 챌린지와 업적
  - `RecordsStatisticsScreen`: 기록과 통계
- 실제 플레이 화면
  - `SudokuGameScreen`: 게임 UI 조립
  - `GameSessionController`: 세션 복원/저장/정리
  - `GameSettingsController`: 게임 화면 설정 로드
  - `GameEndFlow`: 완료/실패/공유 흐름

## 디렉터리 개요

```text
lib/
  constants/     화면/통계 필터 상수
  database/      SQLite 저장소와 repository 계층
  l10n/          로컬라이제이션 코드와 헬퍼
  model/         SudokuLevel, SudokuGame 등 도메인 모델
  navigation/    탭 이동용 scope
  presenter/     게임 플레이 로직과 보드 제어
  services/      홈 대시보드, 업적, 챌린지, 세션, 설정 등 앱 서비스
  theme/         앱 테마
  utils/         퍼즐 생성기, board codec, logger
  view/          화면 단위 UI
  view/sudoku_game/
                 게임 화면 전용 흐름/컨트롤러/서브 UI
  widgets/       공용 위젯
```

## 데이터 저장 전략

- 퍼즐 원본과 클리어 기록은 SQLite에 저장합니다.
  - 관련 진입점: [`lib/database/database_manager.dart`](lib/database/database_manager.dart)
- 진행 중 세션은 `SharedPreferences`에 저장합니다.
  - 관련 진입점: [`lib/services/game_state_service.dart`](lib/services/game_state_service.dart)
- 홈 대시보드는 저장 세션, 퍼즐 엔트리, 업적/챌린지 정보를 조합해서 화면용 데이터로 만듭니다.
  - 관련 진입점: [`lib/services/home_dashboard_service.dart`](lib/services/home_dashboard_service.dart)

## 게임 화면 책임 분리

`SudokuGameScreen`은 최근 리팩터링으로 책임을 나눠둔 상태입니다.

- 세션 처리: [`lib/view/sudoku_game/game_session_controller.dart`](lib/view/sudoku_game/game_session_controller.dart)
- 설정 처리: [`lib/view/sudoku_game/game_settings_controller.dart`](lib/view/sudoku_game/game_settings_controller.dart)
- 종료 흐름: [`lib/view/sudoku_game/game_end_flow.dart`](lib/view/sudoku_game/game_end_flow.dart)
- 완료 데이터 준비: [`lib/view/sudoku_game/game_completion_coordinator.dart`](lib/view/sudoku_game/game_completion_coordinator.dart)

이 구조 덕분에 화면 파일은 UI 상태와 상호작용 쪽에 더 집중하고, 저장/설정/결과 후처리는 별도 객체가 담당합니다.

## 퍼즐 데이터 생성 방식

- DB가 비어 있으면 레벨별 초기 시드 퍼즐을 생성합니다.
- 앱 오픈 시 부족한 퍼즐 수를 백그라운드에서 보충합니다.
- 기본 목표 수량은 레벨별 100개입니다.

관련 구현은 [`lib/database/database_manager.dart`](lib/database/database_manager.dart)에 있습니다.

## 개발 시작

```bash
flutter pub get
flutter run
```

## 검증

푸시 전에 아래 스크립트 실행을 권장합니다.

```bash
bash scripts/verify.sh
```

이 스크립트는 다음을 수행합니다.

- `._*` AppleDouble 파일 제거
- `flutter pub get`
- `flutter analyze`
- `flutter test`

## 테스트

- 단위/위젯 테스트: `test/`
- 통합 테스트: `integration_test/`

```bash
flutter test
flutter test integration_test
```

## 참고

macOS 환경에서는 `._*` 파일이 생기면 Flutter/Dart 테스트가 UTF-8 오류로 실패할 수 있습니다. 필요하면 아래 스크립트로 정리할 수 있습니다.

```bash
bash tool/clean_apple_double.sh
```
