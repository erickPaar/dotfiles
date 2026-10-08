#!/bin/bash
# Move all workspaces to the currently focused monitor
focused_output=$(i3-msg -t get_workspaces 2>/dev/null | python3 -c "
import json, sys
for w in json.load(sys.stdin):
    if w['focused']:
        print(w['output'])
        break
" 2>/dev/null)

[ -z "$focused_output" ] && exit 1

for ws in $(i3-msg -t get_workspaces 2>/dev/null | python3 -c "
import json, sys
for w in json.load(sys.stdin):
    print(w['name'])
" 2>/dev/null); do
    i3-msg "workspace $ws; move workspace to output $focused_output" >/dev/null 2>&1
done
