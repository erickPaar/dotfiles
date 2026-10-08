#!/bin/bash
# Center mouse on the focused window
command -v xdotool >/dev/null || exit 0
eval $(xdotool getwindowfocus getwindowgeometry --shell 2>/dev/null) || exit 0
[ -n "$WIDTH" ] && [ -n "$HEIGHT" ] || exit 0
xdotool mousemove --window "$WINDOW" $((WIDTH/2)) $((HEIGHT/2)) 2>/dev/null
