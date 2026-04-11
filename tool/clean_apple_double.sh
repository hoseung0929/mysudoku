#!/usr/bin/env bash
# macOS가 만드는 AppleDouble(._*) 파일은 Flutter/Dart 도구와 CocoaPods/Xcode 작업에
# 예상치 못한 오류를 일으킬 수 있습니다. 저장소 전반을 정리하되, .git 및 외부/생성물
# 심볼릭 링크 트리는 제외해 권한 오류를 피합니다.
set -euo pipefail

cd "$(dirname "$0")/.."

find . \
  \( \
    -path './.git' -o \
    -path './build' -o \
    -path './.dart_tool' -o \
    -path './linux/flutter/ephemeral' -o \
    -path './ios/Pods' -o \
    -path './macos/Pods' -o \
    -path './ios/.symlinks' -o \
    -path './ios/Flutter/ephemeral' -o \
    -path './macos/Flutter/ephemeral' -o \
    -path './windows/flutter/ephemeral' \
  \) -prune -o \
  -name '._*' -type f -exec rm -f {} +

echo "Done: removed ._ files across the repository (excluding .git and generated symlink trees)."
