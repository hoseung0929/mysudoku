# App Store Connect 개인정보 라벨(App Privacy) 체크리스트

Sudoku159는 외부 서버 없이 전부 로컬 저장이며, `SUDOKU_API_BASE_URL`이 설정되지 않은 기본 배포 빌드에서는 앱 밖으로 나가는 데이터가 없습니다. App Store Connect > App Privacy 설문에서 아래와 같이 체크하면 실제 동작과 일치합니다.

## 1. 데이터 수집 여부

**"Data Not Collected" 선택**

- 프로필 이미지: `image_picker`로 로컬 파일만 다루며 서버 전송 없음 ([profile_image_service.dart](../lib/services/profile/profile_image_service.dart))
- 게임 기록/통계: `sqflite` 로컬 DB에만 저장 ([database](../lib/database))
- 설치 ID: `install_id_service.dart`에서 로컬 랜덤 생성 후 `shared_preferences`에만 저장, 어디에도 전송되지 않음
- 원격 카탈로그(`remote_puzzle_service.dart`)는 `SUDOKU_API_BASE_URL` 미설정 시 완전 비활성 — 현재 CI/빌드 스크립트 어디서도 이 값을 설정하지 않음을 확인함

## 2. 빌드 시 재확인할 것

`SUDOKU_API_BASE_URL`을 실제로 배포 빌드에 주입하게 되면(원격 카탈로그 기능 활성화), 이 체크리스트는 무효가 되고 아래를 다시 검토해야 함:
- 서버로 전송되는 값이 있는지 (`level_name`, `limit` 쿼리 파라미터만 전송되는지 확인)
- 서버가 IP/기기 식별자를 로깅하는지 여부 (앱 코드가 아닌 서버 인프라 문제이므로 별도 확인 필요)
- 위 경우 "Data Not Collected" 대신 실제 수집 항목(예: Usage Data)을 선언해야 함

## 3. 권한 설명 문구 (Info.plist)

- `NSPhotoLibraryUsageDescription`만 존재 (갤러리 전용, 카메라 미사용 — 2026-07-05 정리)
- 실제 사용하지 않는 권한 키가 없는지 제출 전 재확인

## 4. Export Compliance

- `ITSAppUsesNonExemptEncryption = false` — `http` 패키지로 표준 HTTPS만 사용하고 커스텀 암호화 없음. App Store Connect 제출 시 "표준 암호화만 사용" 질문에 그대로 답하면 됨.
