"""Compose a spell C.GIF over the indexed BLANK_SCROLL.GIF canvas."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def compose(blank_scroll: Path, icon: Path, output: Path) -> None:
    base = Image.open(blank_scroll).convert("P")
    overlay = Image.open(icon).convert("P")

    if base.size != overlay.size:
        raise ValueError(
            f"Canvas sizes must match: {blank_scroll} is {base.size}, "
            f"but {icon} is {overlay.size}"
        )

    base_palette = base.getpalette()
    overlay_palette = overlay.getpalette()
    base_pixels = base.load()
    overlay_pixels = overlay.load()
    palette_colors = [
        tuple(base_palette[index * 3 : index * 3 + 3]) for index in range(256)
    ]
    color_indexes: dict[tuple[int, int, int], int] = {}

    overlay_indexes = {
        overlay_pixels[x, y]
        for y in range(overlay.height)
        for x in range(overlay.width)
    }
    for overlay_index in overlay_indexes:
        if overlay_index == 0:
            continue
        color = tuple(overlay_palette[overlay_index * 3 : overlay_index * 3 + 3])
        if color not in color_indexes:
            color_indexes[color] = min(
                range(1, 256),
                key=lambda index: sum(
                    (palette_colors[index][channel] - color[channel]) ** 2
                    for channel in range(3)
                ),
            )

    for y in range(overlay.height):
        for x in range(overlay.width):
            overlay_index = overlay_pixels[x, y]
            if overlay_index != 0:
                color = tuple(
                    overlay_palette[overlay_index * 3 : overlay_index * 3 + 3]
                )
                base_pixels[x, y] = color_indexes[color]

    base.putpalette(base_palette)
    base.info["transparency"] = 0
    output.parent.mkdir(parents=True, exist_ok=True)
    base.save(output, format="GIF", transparency=0, optimize=False)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Overlay a spell C.GIF onto BLANK_SCROLL.GIF."
    )
    parser.add_argument("blank_scroll", type=Path)
    parser.add_argument("icon", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    compose(args.blank_scroll, args.icon, args.output)


if __name__ == "__main__":
    main()
