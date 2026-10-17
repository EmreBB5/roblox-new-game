#!/usr/bin/env python3
"""Check that the Studio XML includes every current Luau source and script type."""
from collections import Counter
from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def verify(export_path: Path) -> None:
    root = Path(__file__).resolve().parent.parent
    expected = Counter()
    for source in (root / "src").rglob("*.luau"):
        kind = (
            "Script" if source.name.endswith(".server.luau")
            else "LocalScript" if source.name.endswith(".client.luau")
            else "ModuleScript"
        )
        expected[(kind, source.read_text(encoding="utf-8"))] += 1
    if not expected:
        raise ValueError("No source files found")

    actual = Counter()
    for item in ET.parse(export_path).iter("Item"):
        properties = item.find("Properties")
        if properties is None:
            continue
        for value in properties:
            if value.get("name") == "Source":
                actual[(item.get("class"), value.text or "")] += 1
    missing, extra = expected - actual, actual - expected
    if missing or extra:
        raise ValueError(
            f"Export source mismatch: {sum(missing.values())} missing/stale, "
            f"{sum(extra.values())} unexpected scripts"
        )
    print(f"Studio export verified: {sum(expected.values())} sources and script types match.")


if __name__ == "__main__":
    checkout = Path(__file__).resolve().parent.parent
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else checkout / "build/Aetheria.rbxlx"
    try:
        verify(target)
    except (OSError, ValueError, ET.ParseError) as error:
        raise SystemExit(str(error)) from error
