#!/usr/bin/env python3
"""Generate per-entry bitmap snippet `.toit` files from a manifest.

This script writes one `.toit` per manifest entry (e.g. `src/util/bitmaps/name.toit`) and
no longer creates a single aggregated `src/util/bitmaps.toit` file.
"""

from __future__ import annotations

import argparse
import json
import shlex
import sys
from pathlib import Path
from typing import Any, Dict, Iterable

from tools.bitmap_toit import convert_bitmap


def _parse_manifest(path: Path) -> list[Dict[str, Any]]:
    manifest = json.loads(path.read_text())
    entries = manifest.get("entries")
    if entries is None or not isinstance(entries, list):
        raise SystemExit("Manifest must contain an 'entries' array")
    filtered: list[Dict[str, Any]] = []
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        if entry.get("enabled", True) is False:
            continue
        filtered.append(entry)
    return filtered


def _build_command(entry: Dict[str, Any], snippet_path: Path) -> str:
    parts: list[str] = [sys.executable, "tools/bitmap_toit.py", entry["source"]]
    if "resize" in entry:
        resize = entry["resize"]
        parts.extend(["--resize", str(resize[0]), str(resize[1])])
    if entry.get("trim"):
        parts.append("--trim")
    if entry.get("invert"):
        parts.append("--invert")
    if "threshold" in entry:
        parts.extend(["--threshold", str(entry["threshold"])])
    per_line = entry.get("per_line")
    if per_line:
        parts.extend(["--per-line", str(per_line)])
    parts.extend(["--name", entry["name"], "--output", str(snippet_path)])
    return " ".join(shlex.quote(part) for part in parts)


def _resize_value(entry: Dict[str, Any]) -> tuple[int, int] | None:
    resize = entry.get("resize")
    if not resize:
        return None
    return (int(resize[0]), int(resize[1]))


def _sanitize_filename(name: str) -> str:
    name = name.strip()
    name = name.replace(" ", "-").replace("_", "-")
    name = "".join(ch for ch in name if ch.isalnum() or ch == "-")
    name = name.strip("-")
    if not name:
        return "bitmap"
    return name.lower()


def _snippet_path(entry: Dict[str, Any]) -> Path:
    snippet_spec = entry.get("snippet")
    if snippet_spec:
        return Path(snippet_spec)
    filename = _sanitize_filename(entry["name"])
    return Path("src/util/bitmaps") / f"{filename}.toit"


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate the bundled bitmap constants")
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path("tools/bitmaps.json"),
        help="Path to the JSON manifest describing all bitmaps to render.",
    )
    # This tool only writes per-entry snippet files; no aggregate output path is supported.
    args = parser.parse_args()

    entries = _parse_manifest(args.manifest)
    if not entries:
        raise SystemExit("No bitmap entries found in manifest")


    for entry in entries:
        snippet_path = _snippet_path(entry)
        command_line = _build_command(entry, snippet_path)
        snippet, processed_image = convert_bitmap(
            source=entry["source"],
            name=entry["name"],
            threshold=entry.get("threshold", 128),
            invert=entry.get("invert", False),
            per_line=entry.get("per_line", 12),
            trim=entry.get("trim", False),
            resize=_resize_value(entry),
            command_line=command_line,
        )
        # Per-entry snippet already written to disk above.
        snippet_path.parent.mkdir(parents=True, exist_ok=True)
        snippet_path.write_text(snippet + "\n")
        processed_path = entry.get("processed_output")
        if processed_path and processed_image:
            processed_file = Path(processed_path)
            processed_file.parent.mkdir(parents=True, exist_ok=True)
            processed_image.save(processed_file)

    # No aggregated output is written.


if __name__ == "__main__":
    main()
