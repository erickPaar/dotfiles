#!/bin/bash
# Toggle bluetooth adapter power on/off.

powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}')
if [ "$powered" = "yes" ]; then
    bluetoothctl power off >/dev/null
else
    bluetoothctl power on >/dev/null
fi
