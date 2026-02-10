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
import io
import math
import urllib.parse
import urllib.request
from PIL import Image

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


def _get_image_size(source: str) -> tuple[int, int]:
    parsed = urllib.parse.urlparse(source)
    if parsed.scheme in ("http", "https"):
        with urllib.request.urlopen(source) as response:
            data = response.read()
        img = Image.open(io.BytesIO(data))
    else:
        img = Image.open(Path(source))
    return img.size  # (width, height)


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
        # If the source is a URL and the manifest requests a max_height, fetch
        # the image to determine scaling before conversion. The helper can
        # accept a resize parameter; compute it here so bitmap_toit does the rest.
        resize = None
        max_h = entry.get("max_height")
        if max_h:
            try:
                w, h = _get_image_size(entry["source"])
                if h > int(max_h):
                    scale = int(max_h) / float(h)
                    resize = (max(1, int(w * scale)), int(max_h))
            except Exception:
                # Fall back to no resize if fetching fails
                resize = None

        snippet, processed_image = convert_bitmap(
            source=entry["source"],
            name=entry["name"],
            threshold=entry.get("threshold", 128),
            invert=entry.get("invert", False),
            per_line=entry.get("per_line", 12),
            trim=entry.get("trim", False),
            resize=resize or _resize_value(entry),
            command_line=command_line,
        )
        # Per-entry snippet already written to disk above.
        snippet_path.parent.mkdir(parents=True, exist_ok=True)
        snippet_path.write_text(snippet + "\n")
        # If manifest provided a processed_output path use it, otherwise
        # write a sensible default next to the snippet so you can inspect it.
        processed_path = entry.get("processed_output")
        if not processed_path:
            # We could output, but do nothing for now
            # processed_file = snippet_path.parent / f"{snippet_path.stem}-processed.png"
            continue
        else:
            processed_file = Path(processed_path)
        if processed_image:
            processed_file.parent.mkdir(parents=True, exist_ok=True)
            processed_image.save(processed_file)

    # No aggregated output is written.


if __name__ == "__main__":
    main()
