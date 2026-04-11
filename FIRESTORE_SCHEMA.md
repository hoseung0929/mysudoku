# Firestore Schema

이 문서는 MySudoku의 공용 퍼즐 카탈로그와 사용자 세이브를 Firestore에 배치할 때의 권장 구조를 정리합니다.

## 1. 공용 퍼즐 카탈로그

경로:

```text
puzzle_catalog/{catalogVersion}/levels/{levelName}/games/{gameId}
```

예시:

```text
puzzle_catalog/v1/levels/초급/games/초급_1
```

권장 필드:

```json
{
  "levelName": "초급",
  "gameNumber": 1,
  "board": [[5,0,0,6,7,8,9,1,2], ...],
  "solution": [[5,3,4,6,7,8,9,1,2], ...],
  "emptyCells": 30,
  "version": 1,
  "checksum": "sha256:...",
  "createdAt": "<server timestamp>"
}
```

메모:

- `gameId`는 `초급_1`처럼 사람이 읽기 쉬운 안정 키를 권장합니다.
- 앱은 현재 `solution`도 로컬에 캐시합니다. 치팅 방지가 더 중요하면 `solution`을 별도 관리자 전용 경로로 분리해야 합니다.

## 2. 오늘의 도전

경로:

```text
daily_challenges/{yyyy-mm-dd}
```

예시 문서:

```json
{
  "date": "2026-04-12",
  "catalogVersion": "v1",
  "levelName": "중급",
  "gameId": "중급_19",
  "gameNumber": 19,
  "updatedAt": "<server timestamp>"
}
```

메모:

- 앱은 `levelName`, `gameNumber` 기준으로 로컬 캐시된 퍼즐을 찾습니다.
- `catalogVersion`을 같이 두면 이후 퍼즐 교체/증설 시 추적이 쉬워집니다.

## 3. 사용자 세이브

경로:

```text
users/{uid}/save_games/{saveId}
```

예시:

```text
users/abc123/save_games/초급_1
```

권장 필드:

```json
{
  "levelName": "초급",
  "gameNumber": 1,
  "board": [[5,3,0,6,7,8,9,1,2], ...],
  "notes": [[[1,2], [], ...], ...],
  "elapsedSeconds": 185,
  "hintsRemaining": 2,
  "wrongCount": 1,
  "isMemoMode": true,
  "hintCells": ["0,1"],
  "isGameComplete": false,
  "isGameOver": false,
  "updatedAtMillis": 1712846400000,
  "updatedAt": "<server timestamp>"
}
```

메모:

- 현재 앱은 `updatedAtMillis` 최신 값을 우선해 로컬과 클라우드 충돌을 단순 해결합니다.
- 여러 기기에서 동시에 같은 세이브를 수정할 수 있으므로, 운영 시에는 `deviceId`와 `revision` 필드를 추가하는 편이 더 안전합니다.

## 4. 인증 전략

- Firestore 읽기/쓰기 규칙은 로그인 사용자를 전제로 합니다.
- 현재 코드에는 Firebase 연결 후 익명 로그인 bootstrap이 포함되어 있습니다.
- 하지만 익명 로그인은 기기 간 이어하기를 보장하지 않습니다.
- 실제로 플레이를 "가지고 가려면" Google / Apple / Email 같은 영구 로그인 계정을 붙이고, 필요 시 익명 계정을 영구 계정으로 링크해야 합니다.

## 5. Rules

기본 규칙 초안은 루트의 [firestore.rules](/Volumes/Ho_SSD/Ho/Project/mysudoku/firestore.rules:1)에 있습니다.
