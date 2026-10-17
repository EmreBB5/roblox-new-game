#!/usr/bin/env python3
"""Execute actual EliteService source with limited orchestration mocks, not physics."""
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def literal(source):
    equals = "="
    while "]" + equals + "]" in source:
        equals += "="
    return "[" + equals + "[" + source + "]" + equals + "]"


def main():
    sources = {name: literal((ROOT / path).read_text()) for name, path in {
        "CONFIG_SOURCE": "src/shared/GameConfig.luau",
        "RULES_SOURCE": "src/shared/EliteRules.luau",
        "SERVICE_SOURCE": "src/server/EliteService.luau",
    }.items()}
    prelude = "\n".join("local " + name + " = " + source for name, source in sources.items())
    output = ROOT / "build/elite-runtime.spec.luau"
    output.parent.mkdir(exist_ok=True)
    mock = literal((ROOT / "tests/elite-runtime.mock.luau").read_text())
    output.write_text(prelude + "\nlocal MOCK_SOURCE = " + mock + "\nlocal run = assert(loadstring(MOCK_SOURCE))()\nrun(CONFIG_SOURCE, RULES_SOURCE, SERVICE_SOURCE, loadstring)\n")
    binary = shutil.which("luau") or str(Path(os.environ.get("AETHERIA_TOOLS_DIR", "/workspace/.tools/aetheria")) / "bin/luau")
    subprocess.run([binary, str(output)], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
