#!/bin/bash
# polybar status indicator for AWS VPN Client
# Three states: service down (alert), connected (good), disconnected (disabled)

if ! pgrep -f ACVC.GTK.Service >/dev/null; then
    echo "%{F#f7768e}󰀦 VPN%{F-}"
    exit 0
fi

# AWS VPN spawns acvc-openvpn (renamed from openvpn) when actually connected.
if pgrep -f acvc-openvpn >/dev/null; then
    echo "%{F#9ece6a} VPN%{F-}"
else
    echo "%{F#565f89} VPN%{F-}"
fi
