# Usage:
#   ddlog-send <service> <message>                    - Send log with service and message
#   ddlog-send <service> <message> <source>            - Send log with custom source (for grok pipeline matching)
#   ddlog-send <service> <message> <source> <tags>     - Send log with extra tags (comma-separated)
#
# Examples:
#   ddlog-send my-api "[outage] something broke"
#   ddlog-send my-api "some log message" my-api-repo "env:production,team:backend"
ddlog-send() {
  local service="${1:?Usage: ddlog-send <service> <message> [source] [tags]}"
  local message="${2:?Usage: ddlog-send <service> <message> [source] [tags]}"
  local source="${3:-$service}"
  local extra_tags="${4:-}"

  local tags="service:${service},env:production"
  if [ -n "$extra_tags" ]; then
    tags="${tags},${extra_tags}"
  fi

  local response
  response=$(curl -s -w "\n%{http_code}" -X POST "https://http-intake.logs.datadoghq.com/api/v2/logs" \
    -H "DD-API-KEY: $DATADOG_API_KEY" \
    -H "Content-Type: application/json" \
    -d "[{
      \"message\": \"$message\",
      \"ddsource\": \"$source\",
      \"ddtags\": \"$tags\",
      \"service\": \"$service\"
    }]")

  local http_code
  http_code=$(echo "$response" | tail -1)
  if [ "$http_code" = "202" ] || [ "$http_code" = "200" ]; then
    echo "✓ Log sent: service=$service source=$source"
    echo "  Message: ${message:0:120}"
    echo "  Tags: $tags"
    echo "  Tip: ddlogs \"service:$service ${message:0:30}\" \"5m\" 5"
  else
    echo "✗ Failed (HTTP $http_code)"
    echo "$response" | head -1
  fi
}

# Usage:
#   dddash list                         - List all dashboards (id, title)
#   dddash search <query>               - Search dashboards by title
#   dddash get <id>                     - Download full dashboard JSON to /tmp/<id>.json
#   dddash widgets <id>                 - List widgets (id, type, title) for a dashboard
#   dddash group <id> <group_id>        - Show widgets inside a group
#   dddash update <id> <file.json>      - Update dashboard from JSON file
#   dddash backup <id>                  - Save a timestamped backup before editing
#
# Workflow: edit a dashboard group
#   dddash backup abc-def-ghi                          # save a backup first
#   dddash get abc-def-ghi                             # download to /tmp/abc-def-ghi.json
#   dddash widgets abc-def-ghi                         # find the group id
#   dddash group abc-def-ghi <group_id>                # inspect the group
#   # edit /tmp/abc-def-ghi.json (modify the group's widgets/layouts)
#   dddash update abc-def-ghi /tmp/abc-def-ghi.json   # push changes
dddash() {
  local api="https://api.datadoghq.com/api/v1/dashboard"
  local auth=(-H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY")
  local cmd="${1:-help}"
  shift 2>/dev/null

  case "$cmd" in
    list)
      curl -s -X GET "$api" "${auth[@]}" \
        | jq -r '.dashboards[] | "\(.id)\t\(.title)"' \
        | column -t -s $'\t'
      ;;

    search)
      if [ -z "$1" ]; then echo "Usage: dddash search <query>"; return 1; fi
      local query="$1"
      curl -s -X GET "$api" "${auth[@]}" \
        | jq -r --arg q "$query" '.dashboards[] | select(.title | test($q; "i")) | "\(.id)\t\(.title)"' \
        | column -t -s $'\t'
      ;;

    get)
      if [ -z "$1" ]; then echo "Usage: dddash get <id>"; return 1; fi
      local file="/tmp/$1.json"
      curl -s -X GET "${api}/$1" "${auth[@]}" > "$file"
      local title
      title=$(jq -r '.title // "unknown"' "$file")
      local count
      count=$(jq '.widgets | length' "$file")
      echo "✓ Saved to $file ($title, $count top-level widgets)"
      ;;

    widgets)
      if [ -z "$1" ]; then echo "Usage: dddash widgets <id>"; return 1; fi
      local file="/tmp/$1.json"
      if [ ! -f "$file" ]; then
        curl -s -X GET "${api}/$1" "${auth[@]}" > "$file"
      fi
      jq -r '.widgets[] | "\(.id)\t\(.definition.type)\t\(.definition.title // "(no title)")"' "$file" \
        | column -t -s $'\t'
      ;;

    group)
      if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: dddash group <dashboard_id> <group_widget_id>"
        return 1
      fi
      local file="/tmp/$1.json"
      if [ ! -f "$file" ]; then
        curl -s -X GET "${api}/$1" "${auth[@]}" > "$file"
      fi
      local gid="$2"
      jq -r --argjson gid "$gid" '.widgets[] | select(.id == $gid) | .definition.widgets[] |
        "\(.id // "new")\t\(.definition.type)\t\(.definition.title // "(no title)")\t\(.layout | "\(.x),\(.y) \(.width)x\(.height)")"' "$file" \
        | column -t -s $'\t'
      ;;

    update)
      if [ -z "$1" ] || [ -z "$2" ] || [ ! -f "$2" ]; then
        echo "Usage: dddash update <id> <file.json>"
        return 1
      fi
      curl -s -X PUT "${api}/$1" "${auth[@]}" \
        -H "Content-Type: application/json" \
        -d @"$2" \
        | jq '{id: .id, title: .title, url: .url, modified_at: .modified_at, errors: .errors}'
      ;;

    backup)
      if [ -z "$1" ]; then echo "Usage: dddash backup <id>"; return 1; fi
      local ts
      ts=$(date +%Y%m%d-%H%M%S)
      local file="/tmp/$1-backup-${ts}.json"
      curl -s -X GET "${api}/$1" "${auth[@]}" > "$file"
      local title
      title=$(jq -r '.title // "unknown"' "$file")
      echo "✓ Backup saved to $file ($title)"
      ;;

    help|*)
      echo "Usage: dddash <command> [args]"
      echo ""
      echo "Commands:"
      echo "  list                              List all dashboards"
      echo "  search <query>                    Search dashboards by title"
      echo "  get <id>                          Download dashboard JSON to /tmp/<id>.json"
      echo "  widgets <id>                      List top-level widgets (id, type, title)"
      echo "  group <dash_id> <group_id>        Show widgets inside a group"
      echo "  update <id> <file.json>           Update dashboard from JSON file"
      echo "  backup <id>                       Save timestamped backup to /tmp/"
      echo ""
      echo "Workflow:"
      echo "  dddash backup abc-def-ghi"
      echo "  dddash get abc-def-ghi"
      echo "  dddash widgets abc-def-ghi"
      echo "  dddash group abc-def-ghi 12345"
      echo "  # edit /tmp/abc-def-ghi.json"
      echo "  dddash update abc-def-ghi /tmp/abc-def-ghi.json"
      echo ""
      echo "Tips:"
      echo "  - Group widgets need explicit layout: {x, y, width, height}"
      echo "  - Use 'manage_status' type for Monitor Summary widgets"
      echo "  - Use 'alert_value' type for single-value alert count widgets"
      echo "  - Use 'alert_graph' type with viz_type=timeseries for alert timelines"
      ;;
  esac
}

# Usage:
#   ddlogs "<query>" [timeframe] [limit]
#
# Timeframe formats:
#   Relative:  "1h", "30m", "7d"              (from now-X to now)
#   Absolute:  "2026-02-25 TO 2026-03-05"     (ISO dates, UTC)
#   From-only: "2026-02-25"                    (from date to now)
#
# Examples:
#   ddlogs "service:my-api 12345" "1h" 20
#   ddlogs "service:my-api 12345" "2026-02-25 TO 2026-03-05" 50
#   ddlogs "service:my-worker" "2026-02-25" 30
ddlogs() {
  local query="${1:-*}"
  local timeframe="${2:-1h}"
  local limit="${3:-20}"

  local from_ts to_ts
  if [[ "$timeframe" == *" TO "* ]]; then
    # Absolute range: "2026-02-25 TO 2026-03-05"
    local from_date="${timeframe%% TO *}"
    local to_date="${timeframe##* TO }"
    from_ts="${from_date}T00:00:00Z"
    to_ts="${to_date}T23:59:59Z"
  elif [[ "$timeframe" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    # Single date: "2026-02-25" (from that date to now)
    from_ts="${timeframe}T00:00:00Z"
    to_ts="now"
  else
    # Relative: "1h", "30m", "7d"
    from_ts="now-$timeframe"
    to_ts="now"
  fi

  curl -s -X POST "https://api.datadoghq.com/api/v2/logs/events/search" \
    -H "DD-API-KEY: $DATADOG_API_KEY" \
    -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"filter\": {\"query\": \"$query\", \"from\": \"$from_ts\", \"to\": \"$to_ts\"}, \"page\": {\"limit\": $limit}}" \
    | jq -r '.data[]? | "\(.attributes.timestamp) | \(.attributes.message // .attributes.attributes.message // "no message")[0:200]"'
}

# Usage:
#   ddmonitor list                      - List all monitors (id, name, status)
#   ddmonitor list <tag>                - List monitors filtered by tag (e.g. "service:my-api")
#   ddmonitor get <id>                  - Get full monitor details
#   ddmonitor create <file.json>        - Create monitor from JSON file
#   ddmonitor update <id> <file.json>   - Update monitor from JSON file
#   ddmonitor delete <id>               - Delete a monitor
#   ddmonitor mute <id> [minutes]       - Mute monitor (default: 60 min)
#   ddmonitor unmute <id>               - Unmute monitor
#   ddmonitor search <name_query>       - Search monitors by name
#   ddmonitor mine [email]              - List monitors created by you (or by email)
ddmonitor() {
  local api="https://api.datadoghq.com/api/v1/monitor"
  local auth=(-H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY")
  local cmd="${1:-help}"
  shift 2>/dev/null

  case "$cmd" in
    list)
      local tag="$1"
      local url="$api"
      if [ -n "$tag" ]; then
        url="${api}?monitor_tags=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$tag'))")"
      fi
      curl -s -X GET "$url" "${auth[@]}" \
        | jq -r '.[] | "\(.id)\t\(.overall_state)\t\(.name)"' \
        | column -t -s $'\t'
      ;;

    get)
      if [ -z "$1" ]; then echo "Usage: ddmonitor get <id>"; return 1; fi
      curl -s -X GET "${api}/$1" "${auth[@]}" | jq .
      ;;

    create)
      if [ -z "$1" ] || [ ! -f "$1" ]; then
        echo "Usage: ddmonitor create <file.json>"
        return 1
      fi
      curl -s -X POST "$api" "${auth[@]}" \
        -H "Content-Type: application/json" \
        -d @"$1" \
        | jq '{id: .id, name: .name, status: .overall_state, created: .created}'
      ;;

    update)
      if [ -z "$1" ] || [ -z "$2" ] || [ ! -f "$2" ]; then
        echo "Usage: ddmonitor update <id> <file.json>"
        return 1
      fi
      curl -s -X PUT "${api}/$1" "${auth[@]}" \
        -H "Content-Type: application/json" \
        -d @"$2" \
        | jq '{id: .id, name: .name, status: .overall_state, modified: .modified}'
      ;;

    delete)
      if [ -z "$1" ]; then echo "Usage: ddmonitor delete <id>"; return 1; fi
      echo -n "Delete monitor $1? [y/N] "
      read -r confirm
      if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        curl -s -X DELETE "${api}/$1" "${auth[@]}" | jq .
      else
        echo "Cancelled."
      fi
      ;;

    mute)
      if [ -z "$1" ]; then echo "Usage: ddmonitor mute <id> [minutes]"; return 1; fi
      local minutes="${2:-60}"
      local end_ts=$(date -d "+${minutes} minutes" +%s 2>/dev/null || date -v+${minutes}M +%s)
      curl -s -X POST "${api}/$1/mute" "${auth[@]}" \
        -H "Content-Type: application/json" \
        -d "{\"end\": $end_ts}" \
        | jq '{id: .id, name: .name, muted: true, mute_until: (.options.silenced // "indefinite")}'
      ;;

    unmute)
      if [ -z "$1" ]; then echo "Usage: ddmonitor unmute <id>"; return 1; fi
      curl -s -X POST "${api}/$1/unmute" "${auth[@]}" \
        | jq '{id: .id, name: .name, muted: false}'
      ;;

    search)
      if [ -z "$1" ]; then echo "Usage: ddmonitor search <name_query>"; return 1; fi
      local query="$1"
      curl -s -X GET "${api}/search?query=$query" "${auth[@]}" \
        | jq -r '.monitors[]? | "\(.id)\t\(.status)\t\(.name)"' \
        | column -t -s $'\t'
      ;;

    mine)
      local email="${1:-$DATADOG_USER_EMAIL}"
      if [ -z "$email" ]; then
        echo "Set DATADOG_USER_EMAIL or pass email: ddmonitor mine <email>"
        return 1
      fi
      curl -s -X GET "$api" "${auth[@]}" \
        | jq -r --arg email "$email" '.[] | select(.creator.email == $email) | "\(.id)\t\(.overall_state)\t\(.name)"' \
        | column -t -s $'\t'
      ;;

    test)
      if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: ddmonitor test <service> <message> [source]"
        echo ""
        echo "Send a test log to trigger a log-based monitor."
        echo "The message must match the monitor's query and any grok parser patterns."
        echo ""
        echo "Examples:"
        echo "  ddmonitor test my-api '[outage] something broke'"
        echo "  ddmonitor test my-api '[health-check] dependency unreachable'"
        return 1
      fi
      local service="$1"
      local message="$2"
      local source="${3:-${service}}"
      ddlog-send "$service" "$message" "$source"
      echo ""
      echo "Monitor should evaluate within ~2 minutes."
      echo "Check status: ddmonitor search <name> | ddmonitor get <id>"
      ;;

    help|*)
      echo "Usage: ddmonitor <command> [args]"
      echo ""
      echo "Commands:"
      echo "  list [tag]                List monitors (optionally filter by tag)"
      echo "  get <id>                  Get full monitor details"
      echo "  create <file.json>        Create monitor from JSON file"
      echo "  update <id> <file.json>   Update monitor from JSON file"
      echo "  delete <id>               Delete a monitor (with confirmation)"
      echo "  mute <id> [minutes]       Mute monitor (default: 60 min)"
      echo "  unmute <id>               Unmute monitor"
      echo "  search <name_query>       Search monitors by name"
      echo "  mine [email]              List monitors you created (auto-detects email)"
      echo "  test <svc> <msg> [src]    Send test log to trigger a log-based monitor"
      ;;
  esac
}
