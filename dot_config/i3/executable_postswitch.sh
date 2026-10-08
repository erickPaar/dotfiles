#!/bin/bash
# Post-monitor-change script
# Use a lock file to prevent concurrent runs

LOCK="/tmp/i3-postswitch.lock"
exec 200>"$LOCK"
flock -n 200 || exit 0

sleep 2

# No compositor: picom and xcompmgr both produce stale-frame artifacts on this machine after KVM/monitor swaps.
pkill xcompmgr 2>/dev/null
pkill picom 2>/dev/null

# Wait for monitors to be fully ready, then relaunch polybar
sleep 1
~/.config/polybar/launch.sh 2>/dev/null

# Restore keyboard layout
setxkbmap -layout br,us -option grp:alt_shift_toggle 2>/dev/null

# Fix cursor
xsetroot -cursor_name left_ptr 2>/dev/null

# Restore wallpaper
feh --bg-fill --no-fehbg ~/Pictures/Wallpapers/cyberpunk.jpg 2>/dev/null
