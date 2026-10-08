#!/bin/bash
# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down (max 5 seconds)
timeout 5 bash -c 'while pgrep -u $UID -x polybar >/dev/null; do sleep 0.2; done' 2>/dev/null

# Kill tray applets while no tray manager is alive: polybar 3.7's internal/tray
# segfaults if an embedded client (snixembed) is killed while docked, which
# took the bar down and left the respawned snixembed icons as orphan
# top-level windows
killall -q snixembed nm-applet
timeout 3 bash -c 'while pgrep -u $UID -x snixembed >/dev/null; do sleep 0.1; done' 2>/dev/null

# Wait for monitors to be ready
sleep 0.5

# Launch polybar on each monitor. Only one bar may own the X11 tray
# selection, so the tray module goes to the primary monitor's bar.
monitors=$(polybar --list-monitors 2>/dev/null | cut -d":" -f1)
primary=$(polybar --list-monitors 2>/dev/null | awk -F: '/primary/{print $1}')
primary=${primary:-$(echo "$monitors" | head -n1)}
if [ -z "$monitors" ]; then
    # Fallback: launch on default monitor
    polybar main-tray &
else
    for m in $monitors; do
        if [ "$m" = "$primary" ]; then
            MONITOR=$m polybar main-tray &
        else
            MONITOR=$m polybar main &
        fi
    done
fi

# Wait for the bar (and its tray) to be mapped, then start tray applets —
# SNI/XEmbed icons don't re-dock reliably after the tray manager restarts
timeout 5 bash -c 'until xwininfo -root -tree 2>/dev/null | grep -q "polybar-main"; do sleep 0.2; done'
sleep 0.5
# Note: librepods + blueman-tray + update-notifier are intentionally NOT
# restarted here — their icons stay hidden (librepods keeps running iconless;
# blueman StatusIcon plugin disabled via gsettings; update-notifier autostart
# is masked in ~/.config/autostart)
~/.local/bin/snixembed --fork
nm-applet &
