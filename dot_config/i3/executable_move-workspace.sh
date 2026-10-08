#!/bin/bash
# No compositor: picom and xcompmgr both produce stale-frame artifacts on this machine.
pkill xcompmgr 2>/dev/null
pkill picom 2>/dev/null
sleep 0.3
i3-msg "move workspace to output next"
