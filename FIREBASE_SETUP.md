# Firebase Setup Guide

이 문서는 MySudoku의 Firestore 공용 퍼즐 카탈로그와 사용자 클라우드 저장을 실제 Firebase 프로젝트에 연결하는 절차를 정리합니다.

현재 앱 코드는 Firebase 설정이 없으면 안전하게 로컬 전용 모드로 동작합니다.  
Firebase를 붙이면 다음 기능이 활성화됩니다.

- 공용 퍼즐 카탈로그 Firestore 다운로드
- 오늘의 도전 Firestore 조회
- 설정 화면에서 이메일 계정 생성 / 로그인
- 사용자 세이브 Firestore 동기화

관련 코드:

- Firebase bootstrap: [lib/services/firebase_bootstrap_service.dart](/Volumes/Ho_SSD/Ho/Project/mysudoku/lib/services/firebase_bootstrap_service.dart:1)
- 인증: [lib/services/firebase_identity_service.dart](/Volumes/Ho_SSD/Ho/Project/mysudoku/lib/services/firebase_identity_service.dart:1)
- 사용자 세이브 동기화: [lib/services/cloud_game_sync_service.dart](/Volumes/Ho_SSD/Ho/Project/mysudoku/lib/services/cloud_game_sync_service.dart:1)
- 퍼즐 카탈로그 조회: [lib/services/firestore_puzzle_service.dart](/Volumes/Ho_SSD/Ho/Project/mysudoku/lib/services/firestore_puzzle_service.dart:1)
- Firestore 스키마: [FIRESTORE_SCHEMA.md](/Volumes/Ho_SSD/Ho/Project/mysudoku/FIRESTORE_SCHEMA.md:1)
- Firestore 규칙: [firestore.rules](/Volumes/Ho_SSD/Ho/Project/mysudoku/firestore.rules:1)

## 1. Firebase 프로젝트 준비

1. Firebase 콘솔에서 새 프로젝트를 만들거나 기존 프로젝트를 선택합니다.
2. Firestore Database를 생성합니다.
3. Authentication을 활성화합니다.

권장 Authentication provider:

- `Email/Password`: 필수
- `Anonymous`: 권장

메모:

- `Anonymous`를 켜면 앱 시작 시 익명 계정으로 먼저 붙고, 이후 이메일 계정 생성 시 같은 계정을 링크해서 진행 데이터를 더 자연스럽게 이어갈 수 있습니다.
- `Anonymous`를 끄더라도 이메일 로그인 후 로컬 저장 데이터를 클라우드로 올릴 수는 있습니다.

## 2. FlutterFire 설정 파일 생성

FlutterFire CLI가 없다면 설치합니다.

```bash
dart pub global activate flutterfire_cli
```

프로젝트 루트에서 FlutterFire 설정을 실행합니다.

```bash
flutterfire configure
```

이 과정이 끝나면 보통 아래 산출물이 생깁니다.

- `lib/firebase_options.dart`
- 플랫폼별 Firebase 설정 파일
  - iOS/macOS: `GoogleService-Info.plist`
  - Android: `google-services.json`

이 저장소에는 위 파일들이 아직 포함되어 있지 않습니다.  
즉, 실제 Firebase 프로젝트 연결은 아직 로컬 환경에서 한 번 더 실행해줘야 합니다.

## 3. Firebase CLI 준비

Firestore Rules 배포를 위해 Firebase CLI를 설치합니다.

```bash
npm install -g firebase-tools
firebase login
```

프로젝트 ID를 연결합니다.

```bash
firebase use <your-project-id>
```

또는 루트의 [.firebaserc.example](/Volumes/Ho_SSD/Ho/Project/mysudoku/.firebaserc.example:1)을 복사해서 `.firebaserc`를 만들고 프로젝트 ID를 넣어도 됩니다.

## 4. Firestore Rules 배포

루트의 [firebase.json](/Volumes/Ho_SSD/Ho/Project/mysudoku/firebase.json:1)은 현재 [firestore.rules](/Volumes/Ho_SSD/Ho/Project/mysudoku/firestore.rules:1)를 배포 대상으로 잡아둡니다.

배포 명령:

```bash
firebase deploy --only firestore:rules
```

현재 규칙의 기본 정책:

- 공용 퍼즐 카탈로그 읽기: 로그인 사용자
- 오늘의 도전 읽기: 로그인 사용자
- 공용 퍼즐/오늘의 도전 쓰기: 관리자만
- 사용자 세이브 읽기/쓰기: 본인만

## 5. Firestore 데이터 넣기

공용 데이터는 아래 컬렉션 구조를 기대합니다.

- `puzzle_catalog/{catalogVersion}/levels/{levelName}/games/{gameId}`
- `daily_challenges/{yyyy-mm-dd}`
- `users/{uid}/save_games/{saveId}`

세부 필드는 [FIRESTORE_SCHEMA.md](/Volumes/Ho_SSD/Ho/Project/mysudoku/FIRESTORE_SCHEMA.md:1)를 기준으로 맞춰 주세요.

현재 앱에서 사용하는 핵심 필드:

- 퍼즐 카탈로그: `levelName`, `gameNumber`, `board`, `solution`
- 오늘의 도전: `date`, `catalogVersion`, `levelName`, `gameNumber`
- 사용자 세이브: `board`, `notes`, `elapsedSeconds`, `updatedAtMillis`

### CSV에서 시드 만들기

이 저장소에는 로컬 퍼즐 원본 CSV인 `sudoku_games.csv`가 포함되어 있습니다.  
이를 Firestore 문서 번들로 변환하거나 바로 업로드하려면 [tool/firestore_seed.dart](/Volumes/Ho_SSD/Ho/Project/mysudoku/tool/firestore_seed.dart:1)를 사용할 수 있습니다.

JSON 시드만 먼저 만들기:

```bash
bash scripts/firestore_seed.sh export
```

이 명령은 기본적으로 `tool/out/firestore_seed_v1.json`을 생성합니다.

필요하면 환경변수로 제어할 수 있습니다.

```bash
CATALOG_VERSION=v1 \
DAILY_START_DATE=2026-04-12 \
DAILY_DAYS=365 \
bash scripts/firestore_seed.sh export
```

REST API로 바로 업로드:

```bash
FIREBASE_PROJECT_ID=your-project-id \
bash scripts/firestore_seed.sh upload
```

오늘의 도전만 다시 만들기:

```bash
DAILY_START_DATE=2026-04-12 \
DAILY_DAYS=30 \
bash scripts/firestore_daily_challenges.sh export
```

오늘의 도전만 바로 업로드:

```bash
FIREBASE_PROJECT_ID=your-project-id \
DAILY_START_DATE=2026-04-12 \
DAILY_DAYS=30 \
bash scripts/firestore_daily_challenges.sh upload
```

메모:

- 업로드는 Firestore REST `documents:commit` endpoint를 사용합니다.
- 배치 크기 기본값은 200문서입니다.
- `FIREBASE_ACCESS_TOKEN`이 없고 `gcloud`가 설치되어 있으면 스크립트가 `gcloud auth application-default print-access-token`으로 토큰을 자동 조회합니다.
- `scripts/firestore_daily_challenges.sh`는 내부적으로 `SEED_SCOPE=daily`로 실행되므로 `daily_challenges` 문서만 갱신합니다.

## 6. 앱 동작 확인

Firebase 연결 후 확인 순서:

1. 앱 실행
2. 설정 화면 진입
3. `클라우드 저장` 섹션 확인
4. 이메일 계정 생성 또는 로그인
5. `지금 동기화` 실행
6. 다른 기기에서 같은 계정으로 로그인 후 이어하기 데이터가 내려오는지 확인

정상 동작 기대값:

- 로그인 전: 로컬 저장만 유지
- 로그인 후: 로컬 세이브 업로드 + 기존 클라우드 세이브 내려받기
- 다음 실행 시: 앱 시작 중 클라우드/로컬 양방향 동기화

## 7. 현재 코드 기준 주의점

- 앱 시작 시 [lib/main.dart](/Volumes/Ho_SSD/Ho/Project/mysudoku/lib/main.dart:26)에서 Firebase 초기화, 로그인 보장, 양방향 세이브 동기화를 시도합니다.
- Firebase 설정이 없으면 bootstrap이 실패해도 앱은 계속 실행됩니다.
- 설정 화면의 클라우드 저장 UI는 Firebase가 준비되지 않으면 비활성 안내 문구를 보여줍니다.
- 이메일 로그인은 붙어 있지만, Google / Apple 로그인은 아직 추가하지 않았습니다.

## 8. 운영 체크리스트

- Firebase Auth에서 `Email/Password` 활성화
- 필요 시 `Anonymous` 활성화
- Firestore production rules 배포
- 공용 퍼즐 카탈로그 업로드
- 오늘의 도전 문서 업로드
- 실제 기기 2대에서 계정 로그인 후 이어하기 동기화 검증
