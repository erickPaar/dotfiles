#!/bin/bash
# polybar status indicator for Bluetooth
# Four states: service down (alert), powered off (disabled), idle (cyan), connected (good)

if ! systemctl is-active --quiet bluetooth; then
    echo "%{F#f7768e}󰂲 BT%{F-}"
    exit 0
fi

powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}')
if [ "$powered" != "yes" ]; then
    echo "%{F#565f89}󰂲 BT%{F-}"
    exit 0
fi

device=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)
if [ -n "$device" ]; then
    echo "%{F#9ece6a}󰂯 ${device}%{F-}"
else
    echo "%{F#7dcfff}󰂯 BT%{F-}"
fi
