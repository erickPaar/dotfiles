#!/bin/bash
# Wraps i3status and injects keyboard layout indicator
i3status -c ~/.config/i3status/config | while read -r line; do
    case "$line" in
        '{"version":'*|'[')
            echo "$line"
            continue
            ;;
    esac

    # Get current keyboard layout (suppress any stderr)
    current_group=$(xset -q 2>/dev/null | grep -oP 'LED mask:\s+\K\d+')
    if [ "$((current_group & 0x1000))" -ne 0 ]; then
        kb="US"
    else
        kb="BR"
    fi

    kb_json="{\"full_text\":\"KB ${kb}\",\"color\":\"#7aa2f7\"}"

    # Lines are either "[...]" (first) or ",[...]" (subsequent)
    if [[ "$line" == ,\[* ]]; then
        echo ",[${kb_json},${line:2}"
    elif [[ "$line" == \[* ]]; then
        echo "[${kb_json},${line:1}"
    else
        echo "$line"
    fi
done
