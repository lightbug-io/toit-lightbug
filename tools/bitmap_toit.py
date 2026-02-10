#!/usr/bin/env python3
"""Produce Toit bitmap constants from a monochrome image."""

from __future__ import annotations

import argparse
import io
import math
import shlex
import sys
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Sequence

try:
    from PIL import Image
except ImportError:  # pragma: no cover - dependency guidance path
    raise SystemExit(
        "Pillow is required to run this script.\n"
        "Install it with `pip install Pillow` or `pip install -r tools/requirements.txt`."
    )

try:
    RESAMPLE_FILTER = Image.Resampling.LANCZOS
except AttributeError:  # pragma: no cover - pillow compatibility
    RESAMPLE_FILTER = Image.LANCZOS


def _sanitize_name(name: str) -> str:
    name = name.strip()
    name = name.replace(" ", "-").replace("_", "-")
    name = "".join(ch for ch in name if ch.isalnum() or ch == "-")
    name = name.strip("-")
    if not name:
        name = "BITMAP"
    if name[0].isdigit():
        name = "BITMAP-" + name
    return name.upper()


def _load_image(source: str) -> Image.Image:
    parsed = urllib.parse.urlparse(source)
    if parsed.scheme in ("http", "https"):
        with urllib.request.urlopen(source) as response:
            data = response.read()
        return Image.open(io.BytesIO(data))
    return Image.open(Path(source))


def _resize_image(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return image.resize(size, RESAMPLE_FILTER)


def _binary_grid_from_image(image: Image.Image, threshold: int) -> list[list[int]]:
    grayscale = image.convert("L")
    width, height = grayscale.size
    pixels = grayscale.load()
    grid: list[list[int]] = []
    for y in range(height):
        row: list[int] = []
        for x in range(width):
            value = pixels[x, y]
            row.append(1 if value < threshold else 0)
        grid.append(row)
    return grid


def _trim_grid(
    grid: list[list[int]]
) -> tuple[list[list[int]], tuple[int, int, int, int] | None]:
    height = len(grid)
    if height == 0:
        return grid, None
    width = len(grid[0])
    min_x = width
    min_y = height
    max_x = -1
    max_y = -1
    for y, row in enumerate(grid):
        for x, bit in enumerate(row):
            if bit:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x == -1:
        return grid, None
    trimmed = [row[min_x : max_x + 1] for row in grid[min_y : max_y + 1]]
    return trimmed, (min_x, min_y, max_x, max_y)


def _pack_bytes(grid: list[list[int]], width: int) -> list[int]:
    bytes_per_row = math.ceil(width / 8)
    packed: list[int] = []
    for row in grid:
        for byte_index in range(bytes_per_row):
            byte = 0
            for bit in range(8):
                col = byte_index * 8 + bit
                bit_value = row[col] if col < width else 0
                byte |= (bit_value << (7 - bit))
            packed.append(byte)
    return packed


def _grid_to_image(grid: list[list[int]]) -> Image.Image:
    height = len(grid)
    width = len(grid[0]) if height else 0
    if width == 0 or height == 0:
        return Image.new("L", (1, 1), 255)
    img = Image.new("L", (width, height), 255)
    pixels = img.load()
    for y, row in enumerate(grid):
        for x, bit in enumerate(row):
            pixels[x, y] = 0 if bit else 255
    return img


def _format_toit(
    name: str,
    width: int,
    height: int,
    values: Sequence[int],
    per_line: int,
    header_comments: list[str] | None = None,
) -> str:
    lines: list[str] = []
    if header_comments:
        lines.extend(header_comments)
    comment = f"// {name.replace('-', ' ').title()} ({width}x{height})"
    lines.append(comment)
    lines.append(f"{name}-WIDTH := {width}")
    lines.append(f"{name}-HEIGHT := {height}")
    lines.append(f"{name}-DATA := #[")

    hex_values = [f"0X{value:02X}" for value in values]
    for idx in range(0, len(hex_values), per_line):
        chunk = hex_values[idx : idx + per_line]
        line = "  " + ",".join(chunk)
        if idx + per_line < len(hex_values):
            line += ","
        lines.append(line)

    lines.append("]")
    return "\n".join(lines)


def convert_bitmap(
    source: str,
    name: str,
    threshold: int = 128,
    invert: bool = False,
    per_line: int = 12,
    trim: bool = False,
    resize: tuple[int, int] | None = None,
    command_line: str | None = None,
) -> tuple[str, Image.Image | None]:
    image = _load_image(source)
    grid = _binary_grid_from_image(image, threshold)
    preview = _grid_to_image(grid)
    if resize:
        preview = preview.resize(resize, RESAMPLE_FILTER)
    grid = _binary_grid_from_image(preview, 128)
    if invert:
        grid = [[1 - bit for bit in row] for row in grid]
    final_grid, bounds = (_trim_grid(grid) if trim else (grid, None))
    width = len(final_grid[0]) if final_grid else 0
    height = len(final_grid)
    if width == 0 or height == 0:
        final_grid = [[0]]
        width = 1
        height = 1
    packed = _pack_bytes(final_grid, width)
    header_comments: list[str] = []
    if command_line:
        header_comments.append(f"// Generated by running: {command_line}")
    else:
        header_comments.append(f"// Source: {source}")
    if bounds:
        min_x, min_y, max_x, max_y = bounds
        header_comments.append(
            f"// Trimmed bounding box: left={min_x}, top={min_y}, right={max_x}, bottom={max_y}"
        )
    snippet = _format_toit(
        _sanitize_name(name),
        width,
        height,
        packed,
        per_line,
        header_comments,
    )
    processed_image = _grid_to_image(final_grid) if width and height else None
    return snippet, processed_image


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert a bitmap or remote image into Toit constants for screen messages."
    )
    parser.add_argument("source", help="Path or URL to the image to convert.")
    parser.add_argument(
        "--name",
        "-n",
        help="Base name for the generated constants (uppercase names with dashes will be enforced).",
    )
    parser.add_argument(
        "--threshold",
        "-t",
        type=int,
        default=128,
        help="Grayscale threshold (0-255) below which pixels are treated as black.",
    )
    parser.add_argument(
        "--invert",
        "-i",
        action="store_true",
        help="Invert the mask so light pixels become black and vice versa.",
    )
    parser.add_argument(
        "--per-line",
        type=int,
        default=12,
        help="How many bytes to emit per line inside the Toit array.",
    )
    parser.add_argument(
        "--trim",
        action="store_true",
        help="Trim whitespace around the bitmap before packing so the dimensions shrink to the content.",
    )
    parser.add_argument(
        "--resize",
        nargs=2,
        type=int,
        metavar=("WIDTH", "HEIGHT"),
        help="Scale the source image to the provided dimensions before converting.",
    )
    parser.add_argument(
        "--processed-output",
        "-p",
        type=Path,
        help="Optional path to save the processed monochrome image (useful for tracking the exact pixels).",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        help="Optional file to write the generated Toit snippet to. Defaults to stdout.",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    if args.threshold < 0 or args.threshold > 255:
        raise SystemExit("Threshold must be between 0 and 255.")
    if args.per_line <= 0:
        raise SystemExit("--per-line must be at least 1.")
    source = args.source
    resize: tuple[int, int] | None = None
    if args.resize:
        width, height = args.resize
        if width <= 0 or height <= 0:
            raise SystemExit("Resize dimensions must be positive integers.")
        resize = (width, height)
    command_line = " ".join(shlex.quote(arg) for arg in [sys.executable, *sys.argv])
    snippet, processed_image = convert_bitmap(
        source=source,
        name=args.name or Path(source).stem,
        threshold=args.threshold,
        invert=args.invert,
        per_line=args.per_line,
        trim=args.trim,
        resize=resize,
        command_line=command_line,
    )
    snippet += "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(snippet)
    else:
        sys.stdout.write(snippet)
    if args.processed_output and processed_image:
        args.processed_output.parent.mkdir(parents=True, exist_ok=True)
        processed_image.save(args.processed_output)


if __name__ == "__main__":
    main()
