#!/usr/bin/env python3
"""Composite the desktop wallpaper into a per-monitor lock-screen background.

Reads live xrandr geometry, scales+center-crops the wallpaper to fill each
monitor, fills gaps with Tokyo Night, optionally dims, caches per geometry+dim,
and prints the PNG path on success. Exits non-zero on any failure so the caller
(lock.sh) can fall back. Env: LOCK_WALLPAPER (empty = parse ~/.fehbg), LOCK_DIM (0-100).
"""
import os
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageEnhance

GAP_COLOR = "#1a1b26"


def wallpaper_path():
    wp = os.environ.get("LOCK_WALLPAPER", "").strip()
    if wp:
        return Path(os.path.expanduser(wp))
    fehbg = Path.home() / ".fehbg"
    if fehbg.is_file():
        m = re.search(r"'([^']+)'", fehbg.read_text())
        if m:
            return Path(m.group(1))
    return None


def main():
    wp = wallpaper_path()
    if not wp or not wp.is_file():
        return 1

    out = subprocess.run(["xrandr"], capture_output=True, text=True).stdout
    total = re.search(r"current (\d+) x (\d+)", out)
    if not total:
        return 1
    W, H = int(total.group(1)), int(total.group(2))
    monitors = [tuple(map(int, m)) for m in re.findall(r"(\d+)x(\d+)\+(\d+)\+(\d+)", out)]
    if not monitors:
        monitors = [(W, H, 0, 0)]

    try:
        dim = max(0, min(100, int(float(os.environ.get("LOCK_DIM", "100") or "100"))))
    except ValueError:
        dim = 100

    cache_dir = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    cache_dir.mkdir(parents=True, exist_ok=True)
    cache = cache_dir / f"i3lock-bg-{W}x{H}-d{dim}-{wp.stem}.png"

    if cache.is_file() and cache.stat().st_mtime >= wp.stat().st_mtime:
        print(cache)
        return 0

    canvas = Image.new("RGB", (W, H), GAP_COLOR)
    src = Image.open(wp).convert("RGB")
    iw, ih = src.size
    for mw, mh, x, y in monitors:
        scale = max(mw / iw, mh / ih)
        rw, rh = max(1, round(iw * scale)), max(1, round(ih * scale))
        tile = src.resize((rw, rh), Image.LANCZOS)
        left, top = (rw - mw) // 2, (rh - mh) // 2
        canvas.paste(tile.crop((left, top, left + mw, top + mh)), (x, y))

    if 0 < dim < 100:
        canvas = ImageEnhance.Brightness(canvas).enhance(dim / 100.0)

    canvas.save(cache, "PNG")
    print(cache)
    return 0


if __name__ == "__main__":
    sys.exit(main())
