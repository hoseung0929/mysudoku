# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```


Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## Project: Sudoku159

Flutter 스도쿠 퍼즐 게임. iOS/Android 타깃, 무료 앱, 외부 서버 없이 전부 로컬 저장.

### 기술 스택

- **Flutter** 3.2.3+, Dart
- **DB**: `sqflite` (게임 기록), `shared_preferences` (설정)
- **알림**: `flutter_local_notifications`
- **사진**: `image_picker` (프로필 이미지, 갤러리 전용)
- **공유**: `share_plus`
- **네트워크**: `http` — `SUDOKU_API_BASE_URL` 환경변수가 비어있으면 비활성화

### 디렉토리 구조 (`lib/`)

```
model/          데이터 모델 (퍼즐, 게임 기록 등)
database/       SQLite 스키마 및 DAO
services/       비즈니스 로직
  catalog/      퍼즐 목록 로딩 (로컬 에셋 + 원격 옵션)
  challenge/    일일 챌린지
  game/         게임 진행 상태
  records/      통계/기록
  settings/     앱 설정, 알림
  profile/      프로필 이미지
  identity/     설치 ID (로컬)
presenter/      상태 관리 (게임, 설정)
view/           화면
  home/         홈 (퍼즐 선택)
  sudoku_game/  게임 플레이
  challenge/    일일 챌린지
  records/      통계
  settings/     설정
widgets/        공용 위젯
theme/          라이트/다크 테마
l10n/           로컬라이제이션 (AppLocalizations)
navigation/     탭 네비게이션
utils/          AppLogger 등 유틸
```

### 로컬라이제이션

- ARB 파일 위치: `arb/app_en.arb`, `arb/app_ko.arb`, `arb/app_ja.arb`
- 지원 언어: 영어(en), 한국어(ko), 일본어(ja)
- 새 문자열 추가 시 세 파일 모두 수정 필요

### 주요 명령어

```bash
flutter pub get           # 의존성 설치
flutter run               # 연결된 디바이스에서 실행
flutter run -d <id>       # 특정 디바이스 지정
flutter build ios         # iOS 빌드
flutter test              # 테스트 실행
flutter gen-l10n          # 로컬라이제이션 코드 재생성
```

### iOS 배포 주의사항

- 최소 iOS 버전: 13.0
- 번들 ID: `com.hoseung.sudoku159`
- `Info.plist` 권한: `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`
- `ITSAppUsesNonExemptEncryption`: `false` (암호화 미사용 선언됨)
