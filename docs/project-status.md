# 프로젝트 현황

한눈에 보는 현황 페이지. 상세한 과거 기록은 [project-status-archive.md](project-status-archive.md), 버전별 변경은 [deploy-history.md](deploy-history.md), 날짜별 작업 상세는 [worklist.md](worklist.md).

## 현재 상태 (2026-10-10)

| 항목 | 상태 |
|---|---|
| 앱 버전 | `1.2.1+5` (글로벌·일본 공용) |
| Sudoku159 (글로벌) | 아카이브·IPA 생성 완료 → **App Store 업로드 여부 확인 필요** |
| Nanpre159 (일본) | 아카이브·IPA 생성 완료 → **업로드 여부 확인 필요**, 1.1.1+3 심사 결과도 미확인 |
| 코드 | 작업 트리 깨끗, 테스트 874개 통과, 분석 0건 |
| 태그 | 없음 (제출 시 `v1.2.1` 남기기) |

## 해야 할 일

| 우선 | 할 일 | 비고 |
|---|---|---|
| 1 | 1.2.1+5 글로벌·일본 업로드·제출 | Organizer에서 Distribute App |
| 2 | 제출 후 `v1.2.1` 태그, deploy-history 갱신 | |
| 3 | nanpre159 1.1.1+3 심사 결과 확인 | 2026-08-17 재제출, 결과 미기록 |
| 4 | 미추적 `docs/app-store/`(44MB)·`docs/design/` 처리 결정 | 올릴지, 제외할지 |

## 최근 완료 (10/04 ~ 10/10)

| 날짜 | 내용 |
|---|---|
| 10/10 | 완료 칸 `CLEAR`/`PERFECT!` 스티커, 상태별 카드 배경, 범례 |
| 10/10 | 다시 풀기 확인창에 최고 기록, 완료 다이얼로그 힌트 문구 제거 |
| 10/10 | 반투명 유리 버튼(레벨 히어로 Continue, 홈 Start challenge) |
| 10/10 | 기록 화면 단순화 + 최근 완료 목록 |
| 10/10 | 버전 1.2.0+4 → 1.2.1+5, 강제 업데이트 화면 리스타일 |
| 10/06~08 | 게임 컨트롤 단순화·플랫 아이콘, 완료 연출 강화 |
| 10/05 | 단계형 일일 챌린지, 튜토리얼 개편, 연습 퍼즐 진입점 숨김 |
| 10/04 | 숫자 고정, 주간 목표, 기록 링 |
| 10/03 | 기록 요약 문장 카드, 도전 달력·업적 기능 제거 |

## 진행 중

- **아이패드 가로 모드·Apple Pencil**: 코드 구현됨, 아이폰 전용 배포라 사용자에겐 미노출. **실기기(아이패드+펜슬) 검증 대기.**

## 백로그 (우선순위순)

| # | 항목 | 상태 |
|---|---|---|
| 1 | 힌트 풀이 설명 2차 기법(pointing, naked pair 등) | 1차(싱글) 완료 |
| 2 | iOS 홈 화면 위젯 | 미착수 |
| 3 | 결과 공유 이미지 카드 | 미착수 (지금은 텍스트 공유 함수만 있고 호출 안 됨) |
| 4 | Game Center 연동 | 미착수 |
| 5 | Apple Watch 앱 | 낮음 |
| 6 | macOS Catalyst 빌드 | 낮음 |

자동 메모 채우기는 구현 완료(백로그에서 제외).

## 결정 보류 / 제외

- **아이패드 스토어 배포**: 펜슬 입력 + 가로 모드 둘 다 완성 후 재검토 (`TARGETED_DEVICE_FAMILY = 1`로 제한 중).
- **변형 스도쿠 재검토**, **수익화(광고/IAP) 도입**: 사용자 결정 필요.
- **제외**: 연습/젠 모드.

## 참고 문서

- [deploy-history.md](deploy-history.md) 버전·제출 이력 · [worklist.md](worklist.md) 작업 상세
- [CLAUDE.md](../CLAUDE.md) 프로젝트 규칙·배포 주의사항 · [ARCHITECTURE.md](../ARCHITECTURE.md)
- [tablet-ui-guidelines.md](tablet-ui-guidelines.md) · [privacy-policy.md](privacy-policy.md) · [app-store-privacy-checklist.md](app-store-privacy-checklist.md)

---
마지막 갱신: 2026-10-10
