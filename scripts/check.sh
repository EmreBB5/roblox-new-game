#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${AETHERIA_TOOLS_DIR:-/workspace/.tools/aetheria}/bin:$PATH"
while IFS= read -r -d '' source; do
  luau-compile --null "$source" >/dev/null
done < <(find src tests -type f -name '*.luau' -print0)
echo 'All Luau syntax checks passed.'
luau-analyze src/shared/*.luau tests/*.luau
for suite in tests/*.spec.luau; do
  luau "$suite"
done
bash scripts/build.sh
