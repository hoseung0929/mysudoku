#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

command_name="${1:-export}"

SEED_SCOPE=daily \
INCLUDE_DAILY=true \
bash scripts/firestore_seed.sh "$command_name"
