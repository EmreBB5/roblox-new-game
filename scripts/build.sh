#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${AETHERIA_TOOLS_DIR:-/workspace/.tools/aetheria}/bin:$PATH"
mkdir -p build
rojo build default.project.json --output build/Aetheria.rbxlx
