#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

command_name="${1:-export}"

input_csv="${INPUT_CSV:-sudoku_games.csv}"
catalog_version="${CATALOG_VERSION:-v1}"
seed_scope="${SEED_SCOPE:-all}"
daily_start_date="${DAILY_START_DATE:-$(date +%F)}"
daily_days="${DAILY_DAYS:-365}"
include_daily="${INCLUDE_DAILY:-true}"
output_path="${OUTPUT_PATH:-tool/out/firestore_seed_${catalog_version}.json}"
database_id="${FIREBASE_DATABASE_ID:-(default)}"
batch_size="${BATCH_SIZE:-200}"
project_id="${FIREBASE_PROJECT_ID:-}"
access_token="${FIREBASE_ACCESS_TOKEN:-}"

common_args=(
  "--scope=${seed_scope}"
  "--input=${input_csv}"
  "--catalog-version=${catalog_version}"
  "--daily-start-date=${daily_start_date}"
  "--daily-days=${daily_days}"
  "--include-daily=${include_daily}"
)

case "$command_name" in
  export)
    echo "Exporting Firestore seed bundle..."
    dart run tool/firestore_seed.dart export \
      "${common_args[@]}" \
      "--output=${output_path}"
    ;;
  upload)
    if [[ -z "$project_id" ]]; then
      echo "FIREBASE_PROJECT_ID is required for upload." >&2
      exit 64
    fi

    if [[ -z "$access_token" ]] && command -v gcloud >/dev/null 2>&1; then
      access_token="$(gcloud auth application-default print-access-token)"
    fi

    if [[ -z "$access_token" ]]; then
      echo "FIREBASE_ACCESS_TOKEN is required for upload." >&2
      echo "Tip: install gcloud or export FIREBASE_ACCESS_TOKEN manually." >&2
      exit 64
    fi

    echo "Uploading Firestore seed bundle to project ${project_id}..."
    FIREBASE_PROJECT_ID="$project_id" \
    FIREBASE_ACCESS_TOKEN="$access_token" \
    FIREBASE_DATABASE_ID="$database_id" \
    dart run tool/firestore_seed.dart upload \
      "${common_args[@]}" \
      "--project-id=${project_id}" \
      "--access-token=${access_token}" \
      "--database-id=${database_id}" \
      "--batch-size=${batch_size}"
    ;;
  *)
    echo "Usage: bash scripts/firestore_seed.sh [export|upload]" >&2
    exit 64
    ;;
esac
