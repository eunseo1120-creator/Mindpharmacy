#!/usr/bin/env python3
"""Prepare the supplied picture-diary scans as transparent game assets."""

from __future__ import annotations

from collections import deque
from pathlib import Path
import sys

from PIL import Image, ImageFilter


def remove_connected_dark_background(source: Path, destination: Path) -> None:
    image = Image.open(source).convert("RGBA")
    image.thumbnail((768, 1152), Image.Resampling.LANCZOS)
    width, height = image.size
    pixels = image.load()
    outside = Image.new("L", image.size, 0)
    outside_pixels = outside.load()
    queue: deque[tuple[int, int]] = deque()

    def eligible(x: int, y: int) -> bool:
        red, green, blue, _ = pixels[x, y]
        return max(red, green, blue) < 105 and abs(red - green) < 34 and abs(green - blue) < 34

    for x in range(width):
        if eligible(x, 0):
            queue.append((x, 0))
        if eligible(x, height - 1):
            queue.append((x, height - 1))
    for y in range(height):
        if eligible(0, y):
            queue.append((0, y))
        if eligible(width - 1, y):
            queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if outside_pixels[x, y] or not eligible(x, y):
            continue
        outside_pixels[x, y] = 255
        if x:
            queue.append((x - 1, y))
        if x + 1 < width:
            queue.append((x + 1, y))
        if y:
            queue.append((x, y - 1))
        if y + 1 < height:
            queue.append((x, y + 1))

    outside = outside.filter(ImageFilter.GaussianBlur(0.8))
    alpha = outside.point(lambda value: 255 - value)
    image.putalpha(alpha)
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination, optimize=True)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: process_diary_assets.py SOURCE DESTINATION")
    remove_connected_dark_background(Path(sys.argv[1]), Path(sys.argv[2]))


if __name__ == "__main__":
    main()
