# App Store Connect 개인정보 라벨(App Privacy) 체크리스트

최종 확인: 2026-09-26 · 기준: 현재 작업 트리(`fix/ipad-landscape-layout`), `pubspec.yaml` 1.1.1+3, iOS Pods Firebase 11.15.0

> 이전 버전의 이 문서는 "기본 배포 빌드에서는 앱 밖으로 나가는 데이터가 없다"고 적었지만, 실제 앱은 시작할 때 Firebase를 초기화하고 Remote Config를 요청하며, Google Fonts는 글꼴 파일을 내려받는다. 아래는 코드와 SDK 매니페스트를 직접 확인한 결과다.

## 1. 실제 포함된 외부 SDK와 네트워크 사용

| SDK / 패키지 | 사용 목적 | 릴리스 빌드 네트워크 요청 | 근거 |
| --- | --- | --- | --- |
| `firebase_core` 3.x (iOS FirebaseCore 11.15.0) | Firebase 초기화 | 초기화 자체는 없음. Remote Config가 Firebase Installations를 통해 설치 식별자(FID)를 발급받을 때 요청 발생 | `lib/main.dart` `Firebase.initializeApp()` |
| `firebase_remote_config` 5.x (FirebaseRemoteConfig·Installations·ABTesting 11.15.0) | **강제 업데이트 확인 전용**: 최소 버전(`min_version_ios`/`_android`)과 업데이트 URL(`update_url_*`)만 읽음. 일본 플레이버는 `*_japan` 키 사용 | **있음**. 앱 시작 시 `fetchAndActivate()`(릴리스는 최소 6시간 간격) | `lib/services/settings/force_update_service.dart` |
| `google_fonts` 8.0.2 | Noto Sans 글꼴 표시 | **있음**. 폰트 파일이 앱에 번들돼 있지 않아 처음 표시할 때 `fonts.gstatic.com`에서 내려받고 기기에 캐시함 (`allowRuntimeFetching` 기본값 true). 위젯 테스트에서 `fonts.gstatic.com` 요청 시도로 실제 확인 | `pubspec.yaml`에 글꼴 에셋 없음 |
| `url_launcher` | 강제 업데이트 화면의 스토어 링크, 개인정보처리방침·문의 링크 | 사용자가 누를 때만 브라우저/스토어/메일 앱을 연다(앱 자체 전송 없음) | |
| `http` | 원격 퍼즐 목록(선택 기능) | **없음**. 아래 2절 참고 | `lib/services/catalog/remote_puzzle_service.dart` |
| `flutter_local_notifications`, `flutter_timezone`, `timezone` | 매일 저녁 8시 로컬 알림 | 없음(기기 내 예약) | |
| `sqflite`, `shared_preferences`, `path_provider`, `image_picker`, `share_plus`, `package_info_plus`, `wakelock_plus`, `flutter_native_splash` | 로컬 저장·사진 선택·시스템 공유 시트·버전 표시·화면 켜짐 유지·스플래시 | 없음 | |

**포함하지 않는 것**: Firebase Analytics, Crashlytics, 광고 SDK(AdMob 등), 기타 분석·추적 SDK. `pubspec.yaml`과 `ios/Podfile.lock`에서 확인.

## 2. 원격 퍼즐 API (Firebase와 별개)

- `remote_puzzle_service.dart`는 빌드 시 `--dart-define=SUDOKU_API_BASE_URL=...`이 있을 때만 동작한다.
- 현재 저장소의 빌드 설정(`ios/Flutter/*.xcconfig`의 `DART_DEFINES`, `scripts/`, Android Gradle)에는 이 값이 없다. → **글로벌·일본 릴리스 모두 비활성**.
- 이 기능을 켜면 `level_name`, `limit` 요청이 자체 서버로 전송되므로 이 문서와 개인정보처리방침을 다시 갱신해야 한다.
- Firebase Remote Config(강제 업데이트)와는 다른 기능이다. 혼동하지 말 것.

## 3. App Store Connect 제출 전 확인할 개인정보 항목

### SDK가 스스로 선언한 수집 항목 (iOS Privacy Manifest)

`ios/Pods/*/PrivacyInfo.xcprivacy`를 직접 읽은 결과:

| Pod | NSPrivacyTracking | 선언된 수집 데이터 |
| --- | --- | --- |
| FirebaseRemoteConfig | false | Other Diagnostic Data — 사용자와 연결 안 됨, 추적 안 함, 목적: Analytics |
| FirebaseInstallations | false | Other Diagnostic Data — 사용자와 연결 안 됨, 추적 안 함, 목적: Analytics |
| FirebaseCore | false | 없음 |

Firebase 공식 안내(https://firebase.google.com/docs/ios/app-store-data-collection)도 Remote Config가 **Analytics 사용 여부와 관계없이** 국가 코드, 언어 코드, 시간대, OS 버전, Firebase 앱 ID, 번들 ID를 파라미터 타기팅용으로 수집한다고 적고 있다. FirebaseCore는 "Does not collect data", Installations는 기기·OS·번들 ID 등으로 구성된 user agent를 식별자와 연결하지 않고 보낸다고 설명한다.

### 판단

- **"Data Not Collected"는 확인 없이 선택하지 않는다.** Firebase SDK 자체 매니페스트가 "Other Diagnostic Data"를 수집 항목으로 선언하고 있어, "Data Not Collected"로 답하면 Xcode 개인정보 리포트와 어긋난다.
- 제출 전에 할 일:
  1. Xcode에서 Archive 후 Organizer → **Generate Privacy Report**를 실행해 앱 전체의 집계 결과(PDF)를 확인한다.
  2. App Store Connect 설문을 그 리포트와 일치시킨다. 리포트대로라면 보수적인 답은 **Diagnostics → Other Diagnostic Data, 사용자와 연결 안 됨, 추적에 사용 안 함**이다(목적은 SDK 선언 기준 Analytics; 앱 입장에서의 실제 용도는 강제 업데이트 확인이므로 App Functionality도 함께 검토).
  3. Google Fonts 요청으로 Google에 IP 주소가 전달되는 점이 "수집"에 해당하는지 판단이 필요하다. 가장 확실한 해결은 5절의 글꼴 번들이다.
- 추적(ATT): 추적 SDK가 없고 모든 매니페스트가 `NSPrivacyTracking = false`라 ATT 팝업·추적 도메인 선언은 필요 없다.

### iOS Privacy Manifest

- 앱: `ios/Runner/PrivacyInfo.xcprivacy` 존재(UserDefaults `CA92.1`, File Timestamp `C617.1`, 추적 false, 수집 항목 없음).
- Firebase 계열(Core, CoreInternal, Installations, RemoteConfig, ABTesting, GoogleUtilities, PromisesObjC)은 각 Pod에 자체 매니페스트가 들어 있다.
- 나머지 Flutter 플러그인의 매니페스트 포함 여부는 개별 확인하지 않았다. Generate Privacy Report에서 "필수 사유 API" 누락 경고가 없는지 같이 확인한다.

## 4. 글로벌·일본 플레이버 차이

| 항목 | 글로벌(Sudoku159) | 일본(Nanpre159) |
| --- | --- | --- |
| 외부 SDK | 동일 | 동일 |
| Firebase 프로젝트 | 공유 | 공유 |
| Remote Config 키 | `min_version_ios`, `update_url_ios` 등 | `*_japan` 접미사 키 |
| 원격 퍼즐 API | 비활성 | 비활성 |
| 앱 언어 | en·ko·ja·zh·es | en·ja·ko (`l10n_japan.yaml`) |
| iOS Info.plist | `ios/Runner/Info.plist` (Debug·Release·Profile, `*-global`) | `ios/Runner/Info-japan.plist` (`Debug-japan`·`Release-japan`·`Profile-japan`) |
| iOS `CFBundleLocalizations` | en·ko·ja·es·zh-Hans | en·ko·ja (중국어·스페인어 미포함) |

두 Info.plist는 `CFBundleLocalizations`만 다르다. `test/ios/info_plist_flavor_test.dart`가 두 파일의 나머지 내용 일치, 각 언어 목록과 `arb/global`·`arb/japan` 언어의 일치, Xcode 구성 9개의 plist 연결을 검사한다. Info.plist에 키를 추가·수정할 때는 두 파일을 함께 바꿔야 한다.

## 5. 후속 작업: Google Fonts 번들 (미적용)

- 사용하는 글꼴: `GoogleFonts.notoSans` / `notoSansTextTheme` 한 종류. 코드에서 쓰는 굵기: 400(normal), 500, 600, 700(bold), 800.
- 번들 방법: Noto Sans TTF(Regular·Medium·SemiBold·Bold·ExtraBold)를 `assets/google_fonts/`에 넣고 `pubspec.yaml` assets에 등록한다. 파일명은 google_fonts 규칙(`NotoSans-SemiBold.ttf` 등)을 따른다. OFL 라이선스 파일을 함께 넣고 `GoogleFonts.config.allowRuntimeFetching = false`로 설정한다.
- 이번에 적용하지 않은 이유: 글꼴 파일(5개, 앱 크기 수 MB 증가)을 외부에서 내려받아 저장소에 추가해야 해서 사용자 확인이 필요하다.
- 적용하면 1절의 Google Fonts 네트워크 요청이 사라지고, 개인정보처리방침 5항의 Google Fonts 문단을 삭제할 수 있다.

## 6. 권한 설명 문구 (Info.plist)

- `NSPhotoLibraryUsageDescription`만 존재(갤러리 전용, 카메라 미사용).
- 알림 권한은 앱 시작 시 요청하지 않는다. 첫 퍼즐 완료 후 앱 내부 안내에서 "알림 받기"를 누르거나, 설정에서 알림을 켤 때만 요청한다. 플러그인 초기화 시 자동 요청도 끔(`DarwinInitializationSettings(requestAlertPermission: false, …)`).

## 7. Export Compliance

- `ITSAppUsesNonExemptEncryption = false` — 표준 HTTPS(Firebase, 글꼴 다운로드)만 사용하고 커스텀 암호화가 없다. "표준 암호화만 사용" 질문에 그대로 답한다.
