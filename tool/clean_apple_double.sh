#!/usr/bin/env bash
# macOS가 만드는 AppleDouble(._*) 파일은 Flutter/Dart 도구와 CocoaPods/Xcode 작업에
# 예상치 못한 오류를 일으킬 수 있습니다. 다만 Flutter plugin symlink 트리는 건너뜁니다.
set -euo pipefail

cd "$(dirname "$0")/.."

apple_double_files=()
while IFS= read -r file; do
  apple_double_files+=("$file")
done < <(
  find . \
    \( \
      -path './.git' -o \
      -path '*/.plugin_symlinks' -o \
      -path '*/.symlinks/plugins' \
    \) -prune -o \
    -name '._*' -type f -print
)

if ((${#apple_double_files[@]} == 0)); then
  echo "Done: no AppleDouble files found."
  exit 0
fi

removed_count=0
failed_count=0

for file in "${apple_double_files[@]}"; do
  if rm -f "$file"; then
    removed_count=$((removed_count + 1))
  else
    failed_count=$((failed_count + 1))
    echo "Warning: failed to remove $file" >&2
  fi
done

echo "Done: removed ${removed_count} AppleDouble files."
if ((failed_count > 0)); then
  echo "Skipped: ${failed_count} files could not be removed." >&2
fi
