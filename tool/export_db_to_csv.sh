#!/usr/bin/env bash
# SQLite 게임 DB → firestore_seed.dart 입력용 CSV 내보내기
#
# 사용법:
#   ./tool/export_db_to_csv.sh [db경로] [출력csv경로]
#
# 인자를 생략하면 macOS 시뮬레이터/데스크톱 앱에서 DB를 자동 탐색합니다.
#
# 예시:
#   ./tool/export_db_to_csv.sh
#   ./tool/export_db_to_csv.sh ~/custom/path/sudoku_games.db
#   ./tool/export_db_to_csv.sh ~/custom/path/sudoku_games.db my_puzzles.csv

set -euo pipefail

DB_PATH="${1:-}"
OUTPUT="${2:-sudoku_games.csv}"

# ── DB 경로 자동 탐색 ──────────────────────────────────────────────────────────
if [[ -z "$DB_PATH" ]]; then
  echo "DB 경로를 탐색합니다..."

  # macOS 데스크톱 앱 (bundle container)
  DESKTOP_DB=$(find "$HOME/Library/Containers" -name "sudoku_games.db" 2>/dev/null | head -1 || true)

  # iOS 시뮬레이터
  SIM_DB=$(find "$HOME/Library/Developer/CoreSimulator/Devices" -name "sudoku_games.db" 2>/dev/null | head -1 || true)

  if [[ -n "$DESKTOP_DB" ]]; then
    DB_PATH="$DESKTOP_DB"
    echo "✅ 데스크톱 앱 DB 발견: $DB_PATH"
  elif [[ -n "$SIM_DB" ]]; then
    DB_PATH="$SIM_DB"
    echo "✅ iOS 시뮬레이터 DB 발견: $DB_PATH"
  else
    echo "❌ sudoku_games.db 를 찾을 수 없습니다."
    echo ""
    echo "직접 경로를 지정해 주세요:"
    echo "  $0 <db경로> [출력csv경로]"
    echo ""
    echo "DB 위치 힌트:"
    echo "  macOS 앱 : ~/Library/Containers/<bundle-id>/Data/Documents/sudoku_games.db"
    echo "  iOS 시뮬: ~/Library/Developer/CoreSimulator/Devices/<uuid>/data/Containers/Data/Application/<uuid>/Documents/sudoku_games.db"
    exit 1
  fi
fi

if [[ ! -f "$DB_PATH" ]]; then
  echo "❌ 파일이 없습니다: $DB_PATH"
  exit 1
fi

# ── sqlite3 존재 확인 ──────────────────────────────────────────────────────────
if ! command -v sqlite3 &>/dev/null; then
  echo "❌ sqlite3 가 설치되어 있지 않습니다."
  echo "   macOS 기본 설치 도구이므로 Xcode Command Line Tools를 설치하세요:"
  echo "   xcode-select --install"
  exit 1
fi

# ── 내보내기 ──────────────────────────────────────────────────────────────────
TOTAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM games;")
echo "총 $TOTAL 개 퍼즐을 내보냅니다 → $OUTPUT"

{
  echo "id,levelName,gameNumber,board,solution"
  sqlite3 -csv "$DB_PATH" \
    "SELECT id, level_name, game_number, board, solution
     FROM games
     ORDER BY level_name, game_number;"
} > "$OUTPUT"

LINE_COUNT=$(( $(wc -l < "$OUTPUT") - 1 ))
echo "✅ 완료: $LINE_COUNT 행 → $OUTPUT"
echo ""
echo "다음 명령으로 Firestore에 업로드할 수 있습니다:"
echo ""
echo "  # 1) JSON 미리 보기 (실제 업로드 전 확인용)"
echo "  dart run tool/firestore_seed.dart export --input=$OUTPUT --daily-start-date=$(date +%Y-%m-%d) --daily-days=365"
echo ""
echo "  # 2) Firestore 업로드"
echo "  FIREBASE_PROJECT_ID=your-project-id \\"
echo "  FIREBASE_ACCESS_TOKEN=\$(gcloud auth application-default print-access-token) \\"
echo "  dart run tool/firestore_seed.dart upload --input=$OUTPUT --daily-start-date=$(date +%Y-%m-%d) --daily-days=365"
