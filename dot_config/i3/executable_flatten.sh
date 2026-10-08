#!/bin/bash
# Flatten the current workspace by moving all windows out and back
set -e

ws=$(i3-msg -t get_workspaces | python3 -c "
import json, sys
for w in json.load(sys.stdin):
    if w['focused']:
        print(w['name'])
        break
")

[ -z "$ws" ] && exit 1
export TARGET_WS="$ws"

ids=$(i3-msg -t get_tree | python3 -c "
import json, sys, os
tree = json.load(sys.stdin)
ws_name = os.environ['TARGET_WS']
def find_ws(node, name):
    if node.get('type') == 'workspace' and node.get('name') == name:
        return node
    for n in node.get('nodes', []):
        r = find_ws(n, name)
        if r: return r
    return None
def get_leaves(node):
    n = node.get('name') or ''
    if node.get('type') == 'con' and not node.get('nodes') and n and 'polybar' not in n:
        return [str(node['id'])]
    out = []
    for c in node.get('nodes', []):
        out.extend(get_leaves(c))
    return out
ws = find_ws(tree, ws_name)
if ws:
    print(' '.join(get_leaves(ws)))
" 2>/dev/null)

[ -z "$ids" ] && exit 0

for id in $ids; do
    i3-msg "[con_id=$id] move to workspace 99" >/dev/null
done
sleep 0.3
for id in $ids; do
    i3-msg "[con_id=$id] move to workspace $ws" >/dev/null
done
i3-msg "workspace $ws" >/dev/null
