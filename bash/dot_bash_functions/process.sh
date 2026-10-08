psf() {
    if [ -z "$1" ]; then
        echo "Usage: psf <process_name>"
        return 1
    fi

    # Fixed width for CMD column - shows about 90 characters
    local cmd_max_width=90

    # Print header
    printf "%-7s %5s %12s %-15s %s\n" "PID" "%CPU" "%MEM" "CMD"

    # Get and format matching processes
    ps -eo pid=,pcpu=,pmem=,comm=,cmd= | grep -i "$1" | grep -v "grep" | while IFS= read -r line; do
        # Parse the line
        local pid=$(echo "$line" | awk '{print $1}')
        local cpu=$(echo "$line" | awk '{print $2}')
        local mem=$(echo "$line" | awk '{print $3}')
        local comm=$(echo "$line" | awk '{print $5}')

        # Get the full command (everything after the 5th field)
        local cmd=$(echo "$line" | awk '{for(i=6;i<=NF;i++) printf "%s ", $i}')

        # Truncate command if too long
        if [ ${#cmd} -gt $cmd_max_width ]; then
            cmd="${cmd:0:$cmd_max_width}..."
        fi

        # Print formatted output with color highlighting
        printf "%-7s %5s %12s %-15s %s\n" "$pid" "$cpu" "$mem" "$comm" "$cmd" | GREP_COLORS='ms=01;31' grep --color=always -iE "$1|$"
    done
}

pscmd() {
    if [ -z "$1" ]; then
        echo "Usage: pscmd <pid>"
        return 1
    fi

    local pid=$1

    # Check if process exists
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo "Error: No process found with PID $pid"
        return 1
    fi

    # Get full command and format it nicely
    ps -p "$pid" -o cmd= | \
        sed 's/ -/\n  -/g' | \
        sed 's/:/:\n    /g' | \
        sed 's/\.jar /\.jar\n    /g'
}
