#!/bin/sh
# Tokyo Night lock screen.
#
# Shows the desktop wallpaper, composited per-monitor at the full virtual-screen
# size (handles the dual-monitor / different-resolution setup and autorandr by
# reading live xrandr geometry). i3lock-color draws a clock + ring on top when
# installed. Degrades gracefully so the screen ALWAYS locks.
#
# Used by both $mod+Escape and xss-lock, so it must run in the foreground
# (--nofork) for xss-lock's --transfer-sleep-lock to track it.

FONT="FiraCode Nerd Font"
DIM_BRIGHTNESS=70          # 100 = wallpaper untouched; lower dims it for legibility

# Lock wallpaper. Empty = track the current desktop wallpaper (parsed from
# ~/.fehbg). Set a path (e.g. ~/Pictures/Wallpapers/tokyonight_cosmic.png) to pin one.
LOCK_WALLPAPER="$HOME/Pictures/Wallpapers/tokyonight2.png"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"

# Find a Python with Pillow (no system install needed — the dev venv has it).
PYBIN=""
for c in "$HOME/dev/venv/bin/python3" python3 python; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import PIL' >/dev/null 2>&1; then
    PYBIN="$c"; break
  fi
done

# Render (or reuse cached) per-monitor wallpaper composite.
bg=""
if [ -n "$PYBIN" ]; then
  out=$(LOCK_WALLPAPER="$LOCK_WALLPAPER" LOCK_DIM="$DIM_BRIGHTNESS" \
        "$PYBIN" "$HOME/.config/i3/lock-bg.py" 2>/dev/null)
  [ -n "$out" ] && [ -r "$out" ] && bg="$out"
fi
# Fall back to any pre-rendered composite matching the current geometry.
if [ -z "$bg" ]; then
  geo=$(xrandr 2>/dev/null | grep -oP 'current \K[0-9]+ x [0-9]+' | head -n1 | tr -d ' ')
  if [ -n "$geo" ]; then
    for f in $(ls -1t "$CACHE_DIR"/i3lock-bg-"$geo"-*.png 2>/dev/null); do
      [ -r "$f" ] && bg="$f" && break
    done
  fi
fi

common="--nofork --ignore-empty-password --show-failed-attempts"

if i3lock --version 2>&1 | grep -qE 'Cassandra Fox|Raymond Li'; then
  # i3lock-color: wallpaper if rendered, else blur the live screen; + clock + ring
  if [ -n "$bg" ]; then src="-i $bg"; else src="--blur 6"; fi
  exec i3lock $common $src \
    --clock --indicator \
    --time-str=%H:%M \
    --date-str="%A  %d %b" \
    --time-font="$FONT" --date-font="$FONT" \
    --verif-font="$FONT" --wrong-font="$FONT" --greeter-font="$FONT" \
    --time-size=48 --date-size=20 \
    --time-color=c0caf5ff --date-color=c0caf5ff \
    --keylayout 1 --layout-font="$FONT" --layout-size=18 --layout-color=7aa2f7ff \
    --radius=110 --ring-width=9 \
    --ring-color=414868ff --inside-color=1a1b26cc --line-uses-inside \
    --keyhl-color=7aa2f7ff --bshl-color=f7768eff \
    --ringver-color=7aa2f7ff --insidever-color=1a1b26cc --verif-color=7aa2f7ff --verif-text="verifying…" \
    --ringwrong-color=f7768eff --insidewrong-color=1a1b26cc --wrong-color=f7768eff --wrong-text="nope" \
    --separator-color=00000000 --noinput-text="" --greeter-text=""
else
  # mainline i3lock: wallpaper if rendered, else solid Tokyo Night (never grey)
  if [ -n "$bg" ]; then exec i3lock $common -i "$bg"; else exec i3lock $common -c 1a1b26; fi
fi
