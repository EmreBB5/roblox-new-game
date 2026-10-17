#!/usr/bin/env python3
"""Install pinned, checksum-verified Roblox CLI tools outside the checkout."""
import hashlib
import io
import os
from pathlib import Path
import platform
import tempfile
import urllib.request
import zipfile

TOOLS = Path(os.environ.get("AETHERIA_TOOLS_DIR", "/workspace/.tools/aetheria"))
# SHA-256 values published on the respective official GitHub release pages.
RELEASES = [
    (
        "rojo-7.7.1-linux-x86_64.zip",
        "https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip",
        "00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4",
        {"rojo"},
    ),
    (
        "luau-0.743-ubuntu.zip",
        "https://github.com/luau-lang/luau/releases/download/0.743/luau-ubuntu.zip",
        "99d45afb4afaee00ba631c526c8e8c76c67b60f6f119953ce6409be6d6953663",
        {"luau", "luau-compile", "luau-analyze"},
    ),
]


def main():
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "AMD64"):
        raise SystemExit("This cloud setup targets Linux x86_64. Install Rojo 7.7.1 locally for Studio.")
    (TOOLS / "cache").mkdir(parents=True, exist_ok=True)
    (TOOLS / "bin").mkdir(exist_ok=True)
    for name, url, expected, executables in RELEASES:
        cached = TOOLS / "cache" / name
        if cached.exists():
            payload = cached.read_bytes()
        else:
            print(f"Downloading {name} from the official release…", flush=True)
            request = urllib.request.Request(url, headers={"User-Agent": "Aetheria-Setup"})
            with urllib.request.urlopen(request, timeout=60) as response:
                payload = response.read()
        actual = hashlib.sha256(payload).hexdigest()
        if actual != expected:
            raise SystemExit(f"Checksum mismatch for {name}; refusing to install. Remove only this cached archive and retry.")
        # No archive content is executed or extracted until its checksum passes.
        cached.write_bytes(payload)
        with zipfile.ZipFile(io.BytesIO(payload)) as archive:
            for executable in sorted(executables):
                matches = [entry for entry in archive.namelist() if Path(entry).name == executable]
                if len(matches) != 1:
                    raise SystemExit(f"Expected one {executable} in {name}")
                target = TOOLS / "bin" / executable
                contents = archive.read(matches[0])
                if target.is_file() and target.read_bytes() == contents:
                    target.chmod(0o755)
                    continue
                # Atomic replacement also works while a previous binary is running.
                with tempfile.NamedTemporaryFile(dir=TOOLS / "bin", delete=False) as temporary:
                    temporary.write(contents)
                    temporary_path = Path(temporary.name)
                try:
                    temporary_path.chmod(0o755)
                    temporary_path.replace(target)
                finally:
                    temporary_path.unlink(missing_ok=True)
        print(f"Verified and installed {name}", flush=True)
    print(f"Tools: {TOOLS / 'bin'}")


if __name__ == "__main__":
    main()
