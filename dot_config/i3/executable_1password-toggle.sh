#!/bin/bash
# Toggle 1Password window: hide-if-visible, summon-if-hidden, launch-if-not-running.

# If the agent isn't running yet, launch it and exit. The for_window rule will catch the window.
if ! pgrep -x 1password >/dev/null; then
    nohup 1password >/dev/null 2>&1 & disown
    exit 0
fi

WS=$(i3-msg -t get_tree | python3 -c '
import json, sys
def walk(n, ws=""):
    if n.get("type") == "workspace": ws = n.get("name", "")
    wp = n.get("window_properties") or {}
    if wp.get("class") == "1Password":
        print(ws); sys.exit(0)
    for c in n.get("nodes", []) + n.get("floating_nodes", []):
        walk(c, ws)
walk(json.load(sys.stdin))
')

if [ -z "$WS" ]; then
    # Process is running but no window — main window may be hidden to tray. Show via the binary.
    1password >/dev/null 2>&1 &
    exit 0
fi

if [ "$WS" = "__i3_scratch" ]; then
    i3-msg '[class="1Password"] scratchpad show, sticky enable, move position center' >/dev/null
else
    i3-msg '[class="1Password"] move scratchpad' >/dev/null
fi
