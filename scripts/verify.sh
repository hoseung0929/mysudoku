#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "[1/4] Removing AppleDouble files"
find . \
  \( \
    -path './.git' -o \
    -path './build' -o \
    -path './.dart_tool' -o \
    -path './windows/flutter/ephemeral' -o \
    -path './ios/Flutter/ephemeral' -o \
    -path './macos/Flutter/ephemeral' \
  \) -prune -o \
  -name '._*' -delete

echo "[2/4] Fetching packages"
flutter pub get

echo "[3/4] Running analyzer"
flutter analyze

echo "[4/4] Running tests"
flutter test
