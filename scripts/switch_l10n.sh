#!/usr/bin/env bash
#
# Flutter's gen-l10n always reads l10n.yaml from the project root and ignores
# --arb-dir when it exists, so building the japan flavor requires swapping
# l10n.yaml to point at arb/japan first. Usage:
#   scripts/switch_l10n.sh japan   # before building --flavor japan
#   scripts/switch_l10n.sh global  # before building --flavor global (default)

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

flavor="${1:-}"
if [[ "$flavor" != "global" && "$flavor" != "japan" ]]; then
  echo "Usage: $0 <global|japan>" >&2
  exit 1
fi

if [[ "$flavor" == "japan" ]]; then
  cp l10n_japan.yaml l10n.yaml
else
  cat > l10n.yaml <<'EOF'
arb-dir: arb/global
template-arb-file: app_en.arb
output-dir: lib/l10n
output-localization-file: app_localizations.dart
EOF
fi

bash tool/clean_apple_double.sh
flutter gen-l10n
echo "l10n.yaml switched to $flavor and lib/l10n regenerated"
