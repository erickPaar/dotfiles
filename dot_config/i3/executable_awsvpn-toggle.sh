#!/bin/bash
# Toggle AWS VPN window: scratchpad-hide if currently visible, summon+sticky+center if hidden.

WS=$(i3-msg -t get_tree | python3 -c '
import json, sys
def walk(n, ws=""):
    if n.get("type") == "workspace": ws = n.get("name", "")
    wp = n.get("window_properties") or {}
    if "AWS VPN" in wp.get("class", ""):
        print(ws); sys.exit(0)
    for c in n.get("nodes", []) + n.get("floating_nodes", []):
        walk(c, ws)
walk(json.load(sys.stdin))
')

if [ -z "$WS" ]; then
    # No AWS VPN window — launch it. for_window rule will float/center/sticky it.
    if ! pgrep -f "/opt/awsvpnclient/AWS VPN Client" >/dev/null; then
        nohup "/opt/awsvpnclient/AWS VPN Client" >/dev/null 2>&1 &
        disown
    fi
    exit 0
fi

if [ "$WS" = "__i3_scratch" ]; then
    i3-msg '[class="AWS VPN Client"] scratchpad show, sticky enable, move position center' >/dev/null
else
    i3-msg '[class="AWS VPN Client"] move scratchpad' >/dev/null
fi
