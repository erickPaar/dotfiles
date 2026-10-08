#!/bin/bash
# polybar status indicator for 1Password
# Two states: running (good), not running (alert)

if pgrep -x 1password >/dev/null; then
    echo "%{F#9ece6a} 1P%{F-}"
else
    echo "%{F#f7768e} 1P%{F-}"
fi
