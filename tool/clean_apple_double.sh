#!/usr/bin/env bash
# macOS가 FAT/exFAT 등에 만드는 AppleDouble(._*) 파일은 flutter gen-l10n·dart test가
# UTF-8이 아니라고 실패하게 할 수 있습니다. 소스 트리 일부만 안전하게 지웁니다.
set -euo pipefail
cd "$(dirname "$0")/.."
for d in arb lib test integration_test; do
  if [[ -d "$d" ]]; then
    find "$d" -name '._*' -type f -delete 2>/dev/null || true
  fi
done
echo "Done: removed ._ files under arb, lib, test, integration_test (if present)."
