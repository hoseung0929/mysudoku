#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "[1/4] Removing AppleDouble files"
bash tool/clean_apple_double.sh

echo "[2/4] Fetching packages"
flutter pub get

echo "[3/4] Running analyzer"
flutter analyze

echo "[4/4] Running tests"
flutter test
