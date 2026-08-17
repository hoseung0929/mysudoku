# 프로젝트 현황

투두/정책 관련 정보를 한곳에서 확인하기 위한 문서. 상태가 바뀔 때마다 갱신한다.

## 진행 중

- **아이패드 가로 모드 지원** — 커밋되지 않은 작업 중 (`ios/Runner/Info.plist`, `lib/main.dart`, `lib/view/sudoku_game/sudoku_game_screen.dart`). 아이패드(태블릿 크기)에서만 가로 방향을 허용하고 아이폰은 세로 고정을 유지하는 분기 로직. 마무리하려면 아이폰 시뮬레이터 회귀 확인 + 아이패드 시뮬레이터로 가로 모드 검증(`TARGETED_DEVICE_FAMILY`를 로컬에서만 `1,2`로 임시 변경 후 반드시 `1`로 복원) 필요. 자세한 원칙은 [tablet-ui-guidelines.md](tablet-ui-guidelines.md) 참고.

## 대기 중

- **nanpre159(일본 플레이버) App Store 재심사** — 2026-08-17 재제출 완료, 결과 대기 중.

## 보류 (의도적으로 미착수)
- **아이패드 정식 스토어 배포** — `TARGETED_DEVICE_FAMILY = 1`(아이폰 전용)로 의도적으로 제한 중. 조건: (1) 애플펜슬 필기 입력, (2) 가로 모드 지원(위 진행 중 항목) 둘 다 구현된 이후로 재검토.

## 정책/가이드 문서 인덱스
- [CLAUDE.md](../CLAUDE.md) — 프로젝트 전반 규칙, 기술 스택, iOS 배포 주의사항
- [tablet-ui-guidelines.md](tablet-ui-guidelines.md) — 아이패드 UI 작업 원칙 및 화면별 적용 현황
- [privacy-policy.md](privacy-policy.md) — 개인정보처리방침 (글로벌/일본 공용)
- [app-store-privacy-checklist.md](app-store-privacy-checklist.md) — 심사용 개인정보 체크리스트
- [ARCHITECTURE.md](../ARCHITECTURE.md) — 아키텍처 문서

---
마지막 갱신: 2026-08-17
