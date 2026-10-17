#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${AETHERIA_TOOLS_DIR:-/workspace/.tools/aetheria}/bin:$PATH"
while IFS= read -r -d '' source; do
  luau-compile --null "$source"
done < <(find src tests -type f -name '*.luau' -print0)
luau-analyze src/shared/*.luau tests/*.luau
luau tests/progression.spec.luau
luau tests/bosses.spec.luau
bash scripts/build.sh
