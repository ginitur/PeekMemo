#!/usr/bin/env python3
"""Build PeekMeow.icns inputs and PeekMeow.ico from the two logo masters.

Full art is used at 48 px and above. The simplified master is used at 32 px
and below so the eyes, ears, and door edge survive.
"""

from __future__ import annotations

import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "Brand"
FULL = BRAND / "PeekMeow-Logo.png"
SMALL = BRAND / "PeekMeow-Logo-Small.png"
ICONSET = BRAND / "AppIcon.iconset"
ICNS = BRAND / "AppIcon.icns"
ICO = ROOT / "windows" / "src" / "PeekMeow.Windows" / "Assets" / "PeekMeow.ico"

# (filename, pixels, simplified)
ICONSET_IMAGES = [
    ("icon_16x16.png", 16, True),
    ("icon_16x16@2x.png", 32, True),
    ("icon_32x32.png", 32, True),
    ("icon_32x32@2x.png", 64, False),
    ("icon_128x128.png", 128, False),
    ("icon_128x128@2x.png", 256, False),
    ("icon_256x256.png", 256, False),
    ("icon_256x256@2x.png", 512, False),
    ("icon_512x512.png", 512, False),
    ("icon_512x512@2x.png", 1024, False),
]

ICO_SIZES = [16, 20, 24, 32, 48, 64, 128, 256]


def render(size: int, simplified: bool, destination: Path) -> None:
    source = SMALL if simplified else FULL
    destination.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["sips", "-s", "format", "png", "-z", str(size), str(size), str(source), "--out", str(destination)],
        check=True,
        stdout=subprocess.DEVNULL,
    )


def write_ico(images: list[tuple[int, bytes]], destination: Path) -> None:
    count = len(images)
    header = struct.pack("<HHH", 0, 1, count)
    directory = bytearray()
    payload = bytearray()
    offset = 6 + 16 * count
    for size, data in images:
        width = 0 if size >= 256 else size
        height = 0 if size >= 256 else size
        directory += struct.pack("<BBBBHHII", width, height, 0, 0, 1, 32, len(data), offset)
        payload += data
        offset += len(data)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(header + directory + payload)


def main() -> int:
    if not FULL.is_file() or not SMALL.is_file():
        print("missing logo masters in Brand/", file=sys.stderr)
        return 1
    if ICONSET.exists():
        for child in ICONSET.iterdir():
            child.unlink()
    ICONSET.mkdir(parents=True, exist_ok=True)
    for name, size, simplified in ICONSET_IMAGES:
        render(size, simplified, ICONSET / name)
    subprocess.run(["iconutil", "-c", "icns", str(ICONSET), "-o", str(ICNS)], check=True)
    ico_images: list[tuple[int, bytes]] = []
    temporary = BRAND / ".ico-build"
    temporary.mkdir(exist_ok=True)
    for size in ICO_SIZES:
        path = temporary / f"{size}.png"
        render(size, size <= 32, path)
        ico_images.append((size, path.read_bytes()))
        path.unlink()
    temporary.rmdir()
    write_ico(ico_images, ICO)
    print(f"wrote {ICNS}")
    print(f"wrote {ICO}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
