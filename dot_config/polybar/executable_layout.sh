#!/bin/bash
H_ICON=$(printf '\uf0db')
V_ICON=$(printf '\uf00b')
TAB_ICON=$(printf '\uf2d0')
STACK_ICON=$(printf '\uf24d')

i3-msg -t get_tree | python3 -c "
import json, sys
tree = json.load(sys.stdin)
def find_parent_layout(node, parent_layout=''):
    layout = node.get('layout','')
    name = node.get('name') or ''
    if node.get('focused') and node.get('type') == 'con' and name:
        print(parent_layout)
        return True
    for n in node.get('nodes', []):
        if find_parent_layout(n, layout):
            return True
    return False
find_parent_layout(tree)
" 2>/dev/null | while read layout; do
    case "$layout" in
        splith)  echo "$H_ICON  H-Split" ;;
        splitv)  echo "$V_ICON  V-Split" ;;
        tabbed)  echo "$TAB_ICON  Tabbed" ;;
        stacked) echo "$STACK_ICON  Stacked" ;;
        *)       echo "$layout" ;;
    esac
done
