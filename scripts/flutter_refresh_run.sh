#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "[1/4] Removing AppleDouble files"
bash tool/clean_apple_double.sh

echo "[2/4] Cleaning Flutter outputs"
flutter clean

echo "[3/4] Restoring packages"
flutter pub get

echo "[4/4] Launching app"
flutter run "$@"
