#!/usr/bin/env python3
"""Turn the supplied atmosphere artwork into a transparent panel mark.

The source is a gold symbol on black. Black becomes transparency so the mark
can sit in the panel corner without a black plate. A short blur keeps the glow.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(
    sys.argv[1]
    if len(sys.argv) > 1
    else ROOT / "Brand" / "PeekMemo-Atmosphere.png"
)
MARK = ROOT / "Brand" / "PeekMemo-Mark.png"
COPIES = [
    ROOT / "windows" / "src" / "PeekMemo.Windows" / "Assets" / "PeekMemoMark.png",
]


def alpha_from_luminance(channel: Image.Image) -> Image.Image:
    def curve(value: int) -> int:
        level = value / 255
        if level <= 0.012:
            return 0
        strength = min(1.0, (level - 0.012) / 0.22)
        return int((strength ** 0.75) * 255)

    return channel.point(curve)


def main() -> int:
    if not SOURCE.is_file():
        print(f"missing {SOURCE}", file=sys.stderr)
        return 1
    image = Image.open(SOURCE).convert("RGBA")
    red, green, blue, _ = image.split()
    peak = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    mask = peak.point(lambda value: 255 if value > 18 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        print("artwork has no visible pixels", file=sys.stderr)
        return 1
    pad = 36
    left = max(0, bounds[0] - pad)
    top = max(0, bounds[1] - pad)
    right = min(image.width, bounds[2] + pad)
    bottom = min(image.height, bounds[3] + pad)
    cropped = image.crop((left, top, right, bottom))
    red, green, blue, _ = cropped.split()
    peak = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    marked = Image.merge("RGBA", (red, green, blue, alpha_from_luminance(peak)))
    marked = marked.filter(ImageFilter.GaussianBlur(radius=2.4))
    marked.thumbnail((720, 720), Image.Resampling.LANCZOS)
    MARK.parent.mkdir(parents=True, exist_ok=True)
    marked.save(MARK, "PNG", optimize=True)
    for copy in COPIES:
        copy.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(MARK, copy)
    print(f"wrote {MARK} {marked.size[0]}x{marked.size[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
