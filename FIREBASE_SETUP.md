# Firebase Setup Guide

이 문서는 Sudoku159에서 Firebase Auth를 연결하는 절차를 정리합니다.

현재 앱 코드는 Firebase 설정이 없으면 안전하게 로컬 전용 모드로 동작합니다. Firebase를 붙이면 설정 화면에서 이메일 계정 생성/로그인과 익명 로그인 흐름을 사용할 수 있습니다.

관련 코드:

- Firebase bootstrap: [lib/services/firebase/firebase_bootstrap_service.dart](/Volumes/Ho_SSD/Ho/Project/sudoku159/lib/services/firebase/firebase_bootstrap_service.dart:1)
- 인증: [lib/services/firebase/firebase_identity_service.dart](/Volumes/Ho_SSD/Ho/Project/sudoku159/lib/services/firebase/firebase_identity_service.dart:1)
- 설정 화면 상태: [lib/presenter/settings/settings_controller.dart](/Volumes/Ho_SSD/Ho/Project/sudoku159/lib/presenter/settings/settings_controller.dart:1)

## 1. Firebase 프로젝트 준비

1. Firebase 콘솔에서 새 프로젝트를 만들거나 기존 프로젝트를 선택합니다.
2. Authentication을 활성화합니다.

권장 Authentication provider:

- `Email/Password`: 필수
- `Anonymous`: 권장

메모:

- `Anonymous`를 켜면 앱 시작 시 익명 계정으로 먼저 붙고, 이후 이메일 계정 생성 시 같은 계정을 링크해서 진행 데이터를 더 자연스럽게 이어갈 수 있습니다.
- `Anonymous`를 끄더라도 이메일 로그인 기능은 사용할 수 있습니다.

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

## 3. 앱 동작 확인

Firebase 연결 후 확인 순서:

1. 앱 실행
2. 설정 화면 진입
3. 계정 섹션 확인
4. 이메일 계정 생성 또는 로그인
5. 로그아웃/재로그인 동작 확인

정상 동작 기대값:

- Firebase 설정 전: 로컬 전용 모드 유지
- Firebase 설정 후: 익명 로그인 또는 이메일 로그인 가능
- 이메일 계정 연결 후: 설정 화면에 계정 식별자 표시

## 4. 운영 체크리스트

- Firebase Auth에서 `Email/Password` 활성화
- 필요 시 `Anonymous` 활성화
- 실제 기기에서 계정 생성, 로그인, 로그아웃 검증
