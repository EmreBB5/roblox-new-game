#!/usr/bin/env python3
"""Run actual server sources with limited orchestration mocks, not Roblox physics."""
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


def run_suite(name, rules, service, extra=""):
    sources = {name: literal((ROOT / path).read_text()) for name, path in {
        "CONFIG_SOURCE": "src/shared/GameConfig.luau",
        "RULES_SOURCE": rules,
        "SERVICE_SOURCE": service,
    }.items()}
    prelude = "\n".join("local " + name + " = " + source for name, source in sources.items())
    output = ROOT / f"build/{name}.spec.luau"
    output.parent.mkdir(exist_ok=True)
    mock = literal((ROOT / f"tests/{name}.mock.luau").read_text(encoding="utf-8"))
    extra_source = literal((ROOT / extra).read_text(encoding="utf-8") if extra else "")
    output.write_text(prelude + "\nlocal MOCK_SOURCE = " + mock + "\nlocal run = assert(loadstring(MOCK_SOURCE))()\nrun(CONFIG_SOURCE, RULES_SOURCE, SERVICE_SOURCE, loadstring, " + extra_source + ")\n", encoding="utf-8")
    binary = shutil.which("luau") or str(Path(os.environ.get("AETHERIA_TOOLS_DIR", "/workspace/.tools/aetheria")) / "bin/luau")
    subprocess.run([binary, str(output)], cwd=ROOT, check=True)


def main():
    run_suite("elite-runtime", "src/shared/EliteRules.luau", "src/server/EliteService.luau")
    run_suite("enemy-runtime", "src/shared/EnemyRules.luau", "src/server/EnemyService.luau")
    run_suite("contract-runtime", "src/shared/Contracts.luau", "src/server/RegionalContractService.luau", "src/shared/Progression.luau")
    run_suite("target-runtime", "src/shared/Combat.luau", "src/server/PlayerActions.luau")


if __name__ == "__main__":
    main()
